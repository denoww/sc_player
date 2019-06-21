fs    = require 'fs'
http  = require 'http'
https = require 'https'

class Download
  @fila: []
  @loading: false
  @exec: (params)->
    pasta = ENV.DOWNLOAD_VIDEOS if params.is_video
    pasta = ENV.DOWNLOAD_IMAGES if params.is_image
    pasta = ENV.DOWNLOAD_AUDIOS if params.is_audio
    pasta = ENV.DOWNLOAD_FEEDS  if params.is_feed
    pasta ||= './downloads'

    path = pasta + params.nome
    fs.stat path, (error, stats)=>
      if !error && alreadyExists(params, stats.size)
        # console.info "Download -> Arquivo já existe: #{params.nome}"
        return next()

      return @fila.push params if @loading
      @loading = true

      file      = fs.createWriteStream(path)
      protocolo = http
      protocolo = https if params.url.match(/https/)
      console.info "Download -> #{params.nome}, URL: #{params.url}"

      unless validURL(params.url)
        console.info '! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! '
        console.info "URL INVÁLIDA: #{params.url}"
        console.info '! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! ! '
        return next()

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
          console.error 'Download -> Error:', error if error
      .on 'error', (error)->
        Download.loading = false
        next()
        console.error 'Download -> Error:', error if error

  validURL = (url)->
    pattern = new RegExp('^(http|https):\\/\\/(\\w+:{0,1}\\w*)?(\\S+)(:[0-9]+)?(\\/|\\/([\\w#!:.?+=&%!\\-\\/]))?', 'i')
    !!pattern.test(url)

  next = ->
    return unless Download.fila.length
    Download.exec(Download.fila.shift())

  alreadyExists = (params, size=null)->
    return size > 1024 if params.is_feed
    margem = 1
    size <= (params.size + margem) &&
    size >= (params.size - margem)

global.Download = Download
