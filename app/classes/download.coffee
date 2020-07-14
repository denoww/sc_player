fs      = require 'fs'
Jimp    = require 'jimp'
http    = require 'http'
path    = require 'path'
https   = require 'https'
sharp   = require 'sharp'
request = require 'request'
  .defaults encoding: null

class Download
  @fila: []
  @loading: false
  @init: ->
    folders  = []
    folders.push global.homePath + '.config/'
    basePath = global.homePath + '.config/sc_player/'

    folders.push basePath
    folders.push basePath + 'downloads'
    folders.push basePath + ENV.DOWNLOAD_VIDEOS
    folders.push basePath + ENV.DOWNLOAD_IMAGES
    folders.push basePath + ENV.DOWNLOAD_AUDIOS
    folders.push basePath + ENV.DOWNLOAD_FEEDS

    for folder in folders
      if !fs.existsSync(folder)
        fs.mkdirSync(folder)
    return
  @exec: (params, opts={})->
    pasta = global.configPath + ENV.DOWNLOAD_VIDEOS if params.is_video
    pasta = global.configPath + ENV.DOWNLOAD_IMAGES if params.is_image
    pasta = global.configPath + ENV.DOWNLOAD_AUDIOS if params.is_audio
    pasta = global.configPath + ENV.DOWNLOAD_FEEDS  if params.is_feed || opts.is_feed
    pasta = global.configPath + 'downloads/' if params.is_logo || opts.is_logo

    unless pasta
      global.logs.error "Download -> exec -> Nenhuma pasta encontrada para #{params.nome_arquivo}!"
      return

    fullPath = pasta + params.nome_arquivo
    fs.stat fullPath, (error, stats)=>
      return next() if !error && alreadyExists(params, stats.size) && !opts.force
      return Download.fila.push Object.assign {}, params, opts if Download.loading
      return next() unless Download.validURL(params.url)

      Download.loading = true
      doDownloadToBuffer params, fullPath, ->
        console.log '    >>>> BAIXADO A FORCA', params.nome_arquivo if opts.force
        Download.loading = false
        next()
  @validURL: (url)->
    pattern = new RegExp('^(http|https):\\/\\/(\\w+:{0,1}\\w*)?(\\S+)(:[0-9]+)?(\\/|\\/([\\w#!:.?+=&%!\\-\\/]))?', 'i')
    patternYoutube = new RegExp('youtube\\.com|youtu\\.be', 'i')
    patternScripts = new RegExp('\\.js|\\.css', 'i')
    !!pattern.test(url) && !patternYoutube.test(url) && !patternScripts.test(url)

  # depracated
  doDownload = (params, fullPath, callback)->
    Jimp.read params.url, (error, image)->
      if error
        global.logs.create "Download -> Jimp #{error}", extra: params: params
        doDownloadAlternative(params, fullPath, callback)
        return

      global.logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"

      posicaoCover = Jimp.VERTICAL_ALIGN_MIDDLE
      if image.bitmap.width / image.bitmap.height < 0.7
        posicaoCover = Jimp.VERTICAL_ALIGN_TOP

      image
        .cover(1648, 927, Jimp.HORIZONTAL_ALIGN_CENTER | posicaoCover)
        .quality(80)
        .write fullPath, (error, img)->
          return callback?() unless error
          global.logs.error "Download -> image #{error}", extra: params: params
          doDownloadAlternative(params, fullPath, callback)
    return

  # depracated
  doDownloadAlternative = (params, fullPath, callback)->
    file      = fs.createWriteStream(fullPath)
    protocolo = http
    protocolo = https if params.url.match(/https/)
    global.logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"

    protocolo.get params.url, (res)->
      res.on 'data', (data)->
        file.write data
      .on 'end', ->
        file.end()
        callback?()
      .on 'error', (error)->
        callback?()
        if error
          global.logs.error "Download -> Error: #{error}",
            extra: url: params.url
            tags: class: 'download'
    .on 'error', (error)->
      callback?()

  doDownloadToBuffer = (params, fullPath, callback)->
    global.logs.create "Download Buffer -> #{params.nome_arquivo}, URL: #{params.url}"

    return unless params.url
    url = encodeURI params.url.trim()

    if url.match /sulamerica-sede-rio\.jpg|AbyzNWSjaoqG1hoESViQ\/photo-5\.jpg|ZpKDMHRTATdCYodfeCbA\/foto-chamada\.jpg/
      global.logs.error "Download -> doDownloadToBuffer: Ignorando imagem problemática",
        extra: url: params.url
        tags: class: 'download'
      callback?()
      return

    # request.get url, (error, resp, buffer)->
    request.get encoding: 'hex', url: url, (error, resp, imageHex)->
      if error || resp.statusCode != 200
        if error
          global.logs.error "Download -> doDownloadToBuffer: #{error}",
            extra: url: params.url
            tags: class: 'download'
        callback?()
        return

      try
        convertBufferToWebp(imageHex, fullPath, callback)
      catch error
        global.logs.error "Download -> doDownloadToBuffer: #{error}",
          extra: path: fullPath
          tags: class: 'download'
        callback?()
    return

  convertBufferToWebp = (imageHex, fullPath, callback)->
    console.log 'convertBufferToWebp', fullPath
    console.log 'length', imageHex.length
    if imageHex.length > 2500000
      console.log ' #####   ####  ######'
      console.log ' ##  ##   ##   ##    '
      console.log ' #####    ##   ## ###'
      console.log ' ##  ##   ##   ##  ##'
      console.log ' #####   ####  ######'

    console.log imageHex.slice(0,8), imageHex.slice(-8)
    if !(imageHex || '').match /^ffd8(.*)ffd9$/
      global.logs.error "Download -> convertBufferToWebp: Hexadecimal da imagem é inválido",
        extra: path: fullPath
        tags: class: 'download'
      callback?()
      return
    else
      console.log 'HEX da imagem é válido'

    image = sharp(Buffer.from(imageHex, 'hex'))
    # ---------------------------------------------------
    # image.toFile 'img.webp'
    # .then (info)->
    #   console.log 'image.resize then', info
    #   callback?()
    # .catch (error)->
    #   console.log 'image.resize catch', error
    #   global.logs.error "Download -> convertBufferToWebp: #{error}",
    #     extra: path: fullPath
    #     tags: class: 'download'
    #   callback?()
    # return
    # ---------------------------------------------------
    image.metadata().then (metadata) ->
      position = sharp.gravity.center
      position = sharp.gravity.north if metadata.width / metadata.height < 0.8
      console.log 'metadata -> position', position
      console.log 'metadata -> sharp.fit.cover', sharp.fit.cover

      image.resize
        fit:      sharp.fit.cover
        width:    1648
        height:   927
        position: position
      .webp quality: 75
      .toFile fullPath
      .then (info)->
        console.log 'image.resize then', info
        callback?()
      .catch (error)->
        console.log 'image.resize catch', error
        global.logs.error "Download -> convertBufferToWebp: #{error}",
          extra: path: fullPath
          tags: class: 'download'
        callback?()
    .catch (error)->
      console.log 'metadata -> catch', error
      global.logs.error "Download -> convertBufferToWebp: #{error}",
        extra: path: fullPath
        tags: class: 'download'
      callback?()
    return

  next = ->
    return unless Download.fila.length
    Download.exec(Download.fila.shift())

  alreadyExists = (params, size=null)->
    return size > 1024 unless params.size
    margem = 2
    size <= (params.size + margem) &&
    size >= (params.size - margem)

Download.init()
global.Download = Download
