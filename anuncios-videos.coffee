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
  CLIENTE_ID = 46
  TV_ID = 3

  listMensagens = []

  downloadFileHttpGet = (file_url)->
    options =
      port: 80
      host: url.parse(file_url).host
      path: url.parse(file_url).pathname

    file_name   = url.parse(file_url).pathname.split('/').pop()
    downloadDir = switch file_name.split('.').pop()
      when 'mp4'        then ENV.DOWNLOAD_VIDEOS
      when 'jpg', 'png' then ENV.DOWNLOAD_IMAGES
      else console.log('FORMATO DESCONHECIDO')

    file = fs.createWriteStream(downloadDir + file_name)

    http.get options, (res)->
      res.on 'data', (data)->
        file.write data
      .on 'end', ()->
        file.end()
        console.log file_name + ' downloaded to ' + downloadDir

  checkList = (port, host)->
    params = port: port, host: host
    http.get params, (res)->
      res.on 'data', (data)->
        downloadFileHttpGet(url) for url in data.list
      .on 'end', ->
        setTimeout checkList(port, host), 1000

  app = express()
  server = app.listen(ENV.HTTP_PORT)
  console.log("HTTP #{ENV.HTTP_PORT} STARTING")

  app.use express.static("#{__dirname}/app/assets/")

  # Resolve o erro do CROSS de Access-Control-Allow-Origin
  app.all '*', (req, res, next)->
    res.header 'Content-Type', 'application/json'
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'
    return res.sendStatus(200) if req.method == 'OPTIONS'
    next()

  app.get '/', (req, res) ->
    console.log "Request GET / params: #{JSON.stringify(req.body)}"
    res.type "text/html"
    res.sendFile "#{__dirname}/app/assets/templates/index.html"

  app.get '/messages', (req, res) ->
    dateFormat = moment().month() + 1
    dateFormat = "0#{dateFormat}" if dateFormat.length < 2
    dateFormat = "#{dateFormat}-#{moment().year()}"

    url = "#{ENV.API_SERVER_URL}/gerenciar/cd/#{ENV.CLIENTE_ID}/#{dateFormat}"
    url = "/midia_indoor.json?cliente=#{ENV.CLIENTE_ID}&midia_indoor_tv=#{ENV.TV_ID}"
    request(url, (error, response, body)->
      console.log 'url', url
      if body[0] == '{'
        json = JSON.parse(body)
        listMensagens = json.list
      else
        console.log '--------- Error to Request -----------'

      params =
        index: 0
        message:
          tempo: 1000
          titulo: 'Titutlo'
          mensagem: 'quaisii'
          tipo_tempo: 'segundos'

      if listMensagens.length != 0
        index = parseInt(req.query.index)
        index = 0 if index > listMensagens.length-1
        params.message = listMensagens[index]

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
    # downloadFileHttpGet(file_url)

