request = require 'request'
moment  = require 'moment'
express = require 'express'

fs      = require 'fs'
RSS     = require 'rss-parser'
Url     = require 'url'
http    = require 'http'
https   = require 'https'
UrlExists = require 'url-exists'

module.exports = (opt={}) ->
  CLIENTE_ID = 46
  TV_ID = 3

  listMensagens = []
  baixandoArquivo = false

  global.filaBaixar = []

  baixarArquivo = (opts={})->
    pasta = ENV.DOWNLOAD_VIDEOS if opts.is_video
    pasta = ENV.DOWNLOAD_IMAGES if opts.is_image
    pasta = ENV.DOWNLOAD_AUDIOS if opts.is_audio
    pasta = ENV.DOWNLOAD_FEEDS  if opts.is_feed

    checkBySize = (size)->
      return size > 1024 if opts.is_feed
      margem = 1
      size <= (opts.size + margem) &&
      size >= (opts.size - margem)

    path = pasta + opts.nome
    fs.stat path, (error, stats)->
      if error || !checkBySize(stats.size)
        if baixandoArquivo
          return global.filaBaixar.push opts

        baixandoArquivo = true
        file = fs.createWriteStream(path)

        protocolo = http
        protocolo = https if opts.url.match(/https/)

        protocolo.get opts.url, (res)->
          res.on 'data', (data)->
            file.write data
          .on 'end', ->
            baixandoArquivo = false
            file.end()
            if global.filaBaixar.length
              baixarArquivo(global.filaBaixar.shift())
          .on 'error', (error)->
            baixandoArquivo = false
            if global.filaBaixar.length
              baixarArquivo(global.filaBaixar.shift())
            console.error 'baixarArquivo -> Error:', error if error
        .on 'error', (error)->
          baixandoArquivo = false
          if global.filaBaixar.length
            baixarArquivo(global.filaBaixar.shift())
          console.error 'baixarArquivo -> Error:', error if error
      else
        console.info "arquivo já existe -> #{opts.nome}"
        if global.filaBaixar.length
  # checkList = (port, host)->
          baixarArquivo(global.filaBaixar.shift())
  global.baixarArquivo = baixarArquivo

  getGradeObj = ->
    url = "#{ENV.API_SERVER_URL}/publicidades/grade.json?id=8"

    request url, (error, response, body)->
      if error || response?.statusCode != 200
        erro = 'Request Failed.'
        erro += " Status Code: #{response.statusCode}." if response?.statusCode
        erro += " #{error}" if error
        err = new Error erro

      return console.error err.message if err

      data = JSON.parse(body)
      return console.error 'Erro: Não existe Dados da Grade!' unless data

      gradeObj =
        id:        data.id
        layout:    data.layout
        musicas:   []
        conteudos: []
        mensagens: []
        resolucao: data.resolucao

      for vinculo in (data.vinculos || []).sortByField('ordem')
        continue unless vinculo.ativado

        item =
          id:         vinculo.id
          ordem:      vinculo.ordem
          titulo:     vinculo.titulo
          ativado:    vinculo.ativado
          horarios:   vinculo.horarios
          segundos:   vinculo.segundos
          tipo_midia: vinculo.tipo_midia

        switch vinculo.tipo_midia
          when 'musica', 'midia'
            if vinculo.midia
              item.url      = vinculo.midia.original
              item.nome     = "#{vinculo.midia.id}.#{vinculo.midia.extension}"
              item.size     = vinculo.midia.size
              item.midia_id = vinculo.midia.id
              item.extensao = vinculo.midia.extension
              item.is_audio = vinculo.midia.is_audio
              item.is_image = vinculo.midia.is_image
              item.is_video = vinculo.midia.is_video

              if item.is_audio
                gradeObj.musicas.push item
              else
                gradeObj.conteudos.push item
              baixarArquivo(item)
          when 'mensagem'
            if vinculo.mensagem
              item.mensagem = vinculo.mensagem.texto
            gradeObj.mensagens.push item
          when 'clima'
            if vinculo.clima
              item.uf      = vinculo.clima.uf
              item.nome    = vinculo.clima.nome
              item.country = vinculo.clima.country
            gradeObj.conteudos.push item
          when 'feed'
            if vinculo.feed
              item.url       = vinculo.feed.url
              item.fonte     = vinculo.feed.fonte
              item.categoria = vinculo.feed.categoria
            gradeObj.conteudos.push item

      salvarGradeObj(gradeObj)
      getFeeds()

  salvarGradeObj = (params)->
    global.grade = params
    dados = JSON.stringify params, null, 2

    fs.writeFile 'playlist.json', dados, (err)->
      return console.error err if err
      console.info 'playlist.json salvo com sucesso!'

  getFeeds = ->
    return unless global.grade?.conteudos
    feedsObj = global.grade.conteudos.select (item)-> item.tipo_midia == 'feed'
    global.feeds ||= {}
    baixarFeeds(feedObj) for feedObj in feedsObj

  baixarFeeds = (params)->
    global.feeds ||= {}
    parserRSS = new RSS(defaultRSS: 2.0)

    parserRSS.parseURL params.url,
    (err, feeds)->
      return console.error 'baixarFeeds -> ERRO:', err if err
      return if (feeds.items || []).empty()

      for feed in feeds.items || []
        if feed.enclosure?.url && feed.enclosure?.type?.match(/image/)
          imageURL = feed.enclosure.url
        else
          # pegando o src da imagem
          imageURL = (feed.content || '').match(/<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/)?[2] || ''
          # substituindo &amp; por &
          imageURL = imageURL.replace(/(&amp;|amp;)+/g, '&')
          # removendo dimensions e resize para pegar a imagem com mais qualidade
          imageURL = imageURL.replace(/(dimensions=(\d+x\d+)|resize=(\d+x\d+))\W?/g, '')

          # se eh uma imagem externa vamos pegar direto da fonte
          if imageURL.match(/\/external_images\?/) && imageURL.match(/url=/)
            imageURL = imageURL.match(/url=(.*)$/)?[1] || imageURL
        continue unless imageURL

        extension = imageURL.split('.').pop()
        nome = imageURL.split('/').pop().removeSpecialCharacters()
        imageNome = "#{params.fonte}-#{params.categoria}-#{nome}"
        if ['jpg', 'jpeg', 'png', 'gif'].includes(extension)
          imageNome = "#{imageNome}.#{extension}"

        feedObj =
          url:    imageURL
          nome:   imageNome
          data:   feed.pubDate
          titulo: feed.title
          is_feed: true
          titulo_feed: params.titulo

        # tratamento imagens UOL
        opcoesURLs = []
        if imageURL.match(/uol(.*)142x100/)
          tamanhos = ['900x506', '956x500', '450x450', '450x600']
          for tamanho in tamanhos
            opcoesURLs.push imageURL.replace(/142x100/, tamanho)
          opcoesURLs.push imageURL

        if opcoesURLs.any()
          verificarUrls.exec feedObj, opcoesURLs
        else
          baixarArquivo(feedObj)

        global.feeds[params.fonte] ||= {}
        global.feeds[params.fonte][params.categoria] ||= index: 0, lista: []
        global.feeds[params.fonte][params.categoria].lista.push feedObj

      salvarFeeds()

  verificarUrls =
    fila: []
    exec: (opts, urls, index=0)->
      if verificarUrls.loading
        @fila.push opts: opts, urls: urls, index: index

      verificarUrls.loading = true
      return onError?() unless urls[index]

      UrlExists urls[index], (error, existe)->
        verificarUrls.loading = false
        if verificarUrls.fila.any()
          item = verificarUrls.fila.shift()
          verificarUrls.exec(item.opts, item.urls, item.index)

        return console.error 'UrlExists ERRO:', error if error

        if existe
          opts.url = urls[index]
          baixarArquivo(opts)
          return

        onError?()
        index++
        verificarUrls.exec(opts, urls, index)

  salvarFeeds = ->
    unless global.feeds
      return console.error 'ERROR: não existe feeds para salvar'

    dados = JSON.stringify global.feeds, null, 2

    fs.writeFile 'feeds.json', dados, (err)->
      return console.error err if err
      console.info 'feeds.json salvo com sucesso!'

  getGradeObj()

  app = express()
  server = app.listen(ENV.HTTP_PORT)
  console.info "HTTP #{ENV.HTTP_PORT} STARTING"

  app.use express.static("#{__dirname}/app/assets/")
  app.use '/downloads/', express.static("#{__dirname}/downloads/")

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
    # getGradeObj()
    res.sendFile "#{__dirname}/app/assets/templates/index.html"

  app.get '/grade', (req, res) ->
    unless global.grade
      getGradeObj()
      res.sendStatus(400)
      return
    res.send JSON.stringify global.grade

  app.get '/feeds', (req, res) ->
    if global.grade && !global.feeds
      getFeeds()
      res.sendStatus(400)
      return
    res.send JSON.stringify global.feeds || {}

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
    return unless listVideos.length

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
    # baixarArquivo(file_url)

