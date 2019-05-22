############# HOW TO USE ###############
# require('./app/httpServer.coffee')
############# HOW TO USE ###############

request = require 'request'
moment  = require 'moment'
express = require 'express'

fs      = require 'fs'
url     = require 'url'
http    = require 'http'
https   = require 'https'

module.exports = (opt={}) ->
  # file_url = 'https://s3.amazonaws.com/rodrigo-erp/videos-exemplos-midia-indoor/RESUMO.mp4';
  # file_url = 'https://s3.amazonaws.com/rodrigo-erp/videos-exemplos-midia-indoor/COMPRAS+-+COTA%C3%87%C3%83O.mp4';
  # file_url = 'https://s3.amazonaws.com/rodrigo-erp/videos-exemplos-midia-indoor/Software+Seu+Condom%C3%ADnio-+Sistema+de+Administra%C3%A7%C3%A3o+Condominial+-+Aplicativo+de+Gest%C3%A3o+para+S%C3%ADndico.mp4';

  CLIENTE_ID = 46
  TV_ID = 3

  listMensagems = []

  download_file_httpget = (file_url)->
    options =
      port: 80
      host: url.parse(file_url).host
      path: url.parse(file_url).pathname

    file_name = url.parse(file_url).pathname.split('/').pop()
    DOWNLOAD_DIR = switch file_name.split('.').pop()
                    when 'mp4' then ENV.DOWNLOAD_VIDEOS
                    when 'jpg', 'png' then  ENV.DOWNLOAD_IMAGES
                    else console.log('FORMATO DESCONHECIDO')

    file = fs.createWriteStream( DOWNLOAD_DIR + file_name)

    http.get(options, (res)->
      res.on('data', (data)->
        file.write data
      ).on('end', ()->
        file.end()
        console.log file_name + ' downloaded to ' + DOWNLOAD_DIR
      )
    )

  check_list = (port, host)->
    params =
      port: port
      host: host
    http.get(params, (res)->
      res.on('data', (data)->
        for url in data.list
          download_file_httpget(url)
      ).on('end', ()->
        setTimeout check_list(port, host), 1000
      )
    )

  app = express()
  server = app.listen(ENV.HTTP_PORT)

  app.use express.static(__dirname + '/app/assets/')

  console.log("HTTP #{ENV.HTTP_PORT} STARTING")

  # Resolve o erro do CROSS de Access-Control-Allow-Origin
  app.all '*', (req, res, next)->

    res.header 'Content-Type', 'application/json'
    res.header "Access-Control-Allow-Origin", "*"
    res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
    res.header "Access-Control-Allow-Headers", "Content-Type, Authorization, X-Requested-With"
    if 'OPTIONS' == req.method
      return res.sendStatus(200)
    next()

  app.get '/', (req, res) ->
    console.log "Request GET / params: #{JSON.stringify(req.body)}"
    res.type("text/html")
    # res.send("<p>Hellow world</p>")
    res.sendFile(__dirname + '/app/assets/templates/index.html')

  app.get '/messages', (req, res) ->
    dateFormat = moment().month()+1
    dateFormat = '0'+dateFormat if dateFormat.length <2
    dateFormat = dateFormat + '-' +moment().year()

    url = "http://staging.seucondominio.com.br/gerenciar/cd/#{ENV.CLIENTE_ID}/#{dateFormat}/midia_indoor.json?cliente=#{ENV.CLIENTE_ID}&midia_indoor_tv=#{ENV.TV_ID}"
    request(url, (error, response, body)->
      console.log 'url', url
      if body[0] == '{'
        json = JSON.parse(body)
        listMensagems = json.list
      else
        console.log '---------Error to Request-----------'

      params =
        index: 0
        message:
          tempo: 1000
          titulo: 'Titutlo'
          mensagem: 'quaisii'
          tipo_tempo: 'segundos'

      if listMensagems.length != 0
        index = parseInt(req.query.index)
        index = 0 if index > listMensagems.length-1
        params.message = listMensagems[index]

        params.message.tempo = switch params.message.tipo_tempo
                               when 'horas' then params.message.tempo*60*60*1000
                               when 'minutos' then params.message.tempo*60*1000
                               when 'segundos' then params.message.tempo*1000

        params.index = index+1
      res.send JSON.stringify params
    )


  app.get '/video', (req, res) ->
    videoId = parseInt(req.query.id) || 0
    console.log 'ID', videoId

    listVideos = fs.readdirSync 'downloads/videos/'
    videoId    = 0 if videoId >= listVideos.length

    console.log 'listVideos', listVideos
    console.log 'listVideos.length', listVideos.length

    path     = 'downloads/videos/' + listVideos[videoId]
    stat     = fs.statSync(path)
    fileSize = stat.size
    range    = req.headers.range

    if range
      parts     = range.replace(/bytes=/, '').split('-')
      start     = parseInt(parts[0], 10)
      end       = if parts[1] then parseInt(parts[1], 10) else fileSize - 1
      chunksize = end - start + 1
      file      = fs.createReadStream(path, {start: start, end: end})
      string    ="bytes #{start}-#{end}/#{fileSize}"
      head      =
        'Content-Range': string
        'Accept-Ranges': 'bytes'
        'Content-Length': chunksize
        'Content-Type': 'video/mp4'
      res.writeHead 206, head
      file.pipe res
      console.log 'chunksize', chunksize
      console.log 'Começando o Video'

    else
      head =
        'Content-Length': fileSize
        'Content-Type': 'video/mp4'
      res.writeHead 200, head
      fs.createReadStream(path).pipe res
      console.log('Terminou o Video')

  app.get '/playlist', (req, res) ->
    listVideos = fs.readdirSync 'downloads/videos/'
    params =
      playlist_length: listVideos.length
    res.send JSON.stringify params

  httpsOpts =
    requestCert: false,
    rejectUnauthorized: false

  https.createServer(httpsOpts, app).listen ENV.HTTPS_PORT, ->
    console.log("HTTPS #{ENV.HTTPS_PORT} STARTING")
    # download_file_httpget(file_url)

