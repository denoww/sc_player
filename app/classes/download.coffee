fs    = require 'fs'
Jimp  = require 'jimp'
path  = require 'path'

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
      return next() if !error && alreadyExists(params, stats.size)
      return Download.fila.push Object.assign {}, params, opts if Download.loading
      return next() unless validURL(params.url)

      Download.loading = true
      Jimp.read params.url, (error, image)->
        if error
          global.logs.error "Download -> #{error}"
          Download.loading = false
          return next()

        global.logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"
        image
          # .resize(1648, Jimp.AUTO, Jimp.RESIZE_BICUBIC)
          # .crop(0, 0, 1648, 927)
          .cover(1648, 927)
          .quality(80)
          .writeAsync(fullPath).then ->
            Download.loading = false
            next()
          .catch (e)->
            Download.loading = false
            next()
            global.logs.error "Download -> Error: #{e}",

  validURL = (url)->
    pattern = new RegExp('^(http|https):\\/\\/(\\w+:{0,1}\\w*)?(\\S+)(:[0-9]+)?(\\/|\\/([\\w#!:.?+=&%!\\-\\/]))?', 'i')
    !!pattern.test(url)

  next = ->
    return unless Download.fila.length
    Download.exec(Download.fila.shift())

  alreadyExists = (params, size=null)->
    return size > 1024 unless params.size
    margem = 1
    size <= (params.size + margem) &&
    size >= (params.size - margem)

Download.init()
global.Download = Download
