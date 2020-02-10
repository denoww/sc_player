fs    = require 'fs'
http  = require 'http'
https = require 'https'
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
      return @fila.push Object.assign {}, params, opts if @loading
      @loading = true

      file      = fs.createWriteStream(fullPath)
      protocolo = http
      protocolo = https if params.url.match(/https/)
      global.logs.create "Download -> #{params.nome_arquivo}, URL: #{params.url}"

      return next() unless validURL(params.url)

      protocolo.get params.url, (res)->
        res.on 'data', (data)->
          file.write data
        .on 'end', ->
          Download.loading = false
          file.end()
          next()
        .on 'error', (error)->
          Download.loading = false
          next()
          if error
            global.logs.error "Download -> Error: #{error}",
              extra: url: params.url
              tags: class: 'download'
      .on 'error', (error)->
        Download.loading = false
        next()
        if error
          global.logs.error "Download -> Error: #{error}",
            extra: url: params.url
            tags: class: 'download'

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
