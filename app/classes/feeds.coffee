fs        = require 'fs'
RSS       = require 'rss-parser'
shell     = require 'shelljs'
request   = require 'request'
path      = require 'path'
UrlExists = require 'url-exists'

module.exports = ->
  ctrl =
    data: {}
    totalItensPorCategoria: 20
    getList: ->
      return unless global.grade?.data?.conteudos?.length
      feeds = global.grade.data.conteudos.select (item)-> item.tipo_midia == 'feed'
      playlists = global.grade.data.conteudos.select (item)-> item.tipo_midia == 'playlist'

      for playlist in playlists
        feeds = feeds.concat playlist.conteudos.select (item)-> item.tipo_midia == 'feed'

      return if feeds.empty()

      @getDataOffline()
      @baixarFeeds(feed) for feed in feeds
    baixarFeeds: (params)->
      parserRSS = new RSS(defaultRSS: 2.0)

      parserRSS.parseURL params.url,
      (error, feeds)=>
        return global.logs.create("Feeds -> baixarFeeds -> ERRO: #{error}") if error
        return if (feeds.items || []).empty()

        @data[params.fonte] ||= {}
        @data[params.fonte][params.categoria] = null
        @handlelist(params, feed) for feed in feeds.items.splice(0, @totalItensPorCategoria)
        @setTimerToSaveDataJson()
      return
    handlelist: (params, feed)->
      image = @getImageData(params, feed)
      return unless image

      feedObj =
        url:          image.url
        titulo:       feed.title
        titulo_feed:  params.titulo
        nome_arquivo: image.nome

      if image.url.match(/uol(.*)142x100/)
        @getImageUol(feedObj, image)
      else if params.fonte == 'infomoney'
        return @getImageInfomoney(params, feedObj, image)
      else
        Download.exec(feedObj, is_feed: true)

      @data[params.fonte] ||= {}
      @data[params.fonte][params.categoria] ||= []
      @data[params.fonte][params.categoria].push feedObj
    getImageData: (params, feed)->
      if feed.enclosure?.url && feed.enclosure?.type?.match(/image/)
        imageURL = feed.enclosure.url
      else
        # pegando o src da imagem
        imageURL = (feed.content || '').match(/<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i)?[2] || ''
        # substituindo &amp; por &
        imageURL = imageURL.replace(/(&amp;|amp;)+/g, '&')
        # removendo dimensions e resize para pegar a imagem com mais qualidade
        imageURL = imageURL.replace(/(dimensions=(\d+x\d+)|resize=(\d+x\d+))\W?/gi, '')

        # se eh uma imagem externa vamos pegar direto da fonte
        if imageURL.match(/\/external_images\?/i) && imageURL.match(/url=/i)
          imageURL = imageURL.match(/url=(.*)$/i)?[1] || imageURL

      if !imageURL && params.fonte == 'infomoney'
        return url: feed.link

      return unless imageURL
      @mountImageData(params, imageURL)
    mountImageData: (params, url)->
      extension = url.match(/\.jpg|\.jpeg|\.png|\.gif|\.webp/i)?[0] || ''
      imageNome = url.split('/').pop().replace(extension, '').removeSpecialCharacters()
      imageNome = "#{params.fonte}-#{params.categoria}-#{imageNome}"
      imageNome = "#{imageNome}#{extension}"

      url: url, nome: imageNome
    verificarUrls:
      fila: []
      exec: (params, urls, index=0)->
        return @fila.push params: params, urls: urls, index: index if @loading
        @loading = true

        UrlExists urls[index], (error, existe)=>
          @loading = false
          @next()
          return global.logs.create("Feeds -> verificarUrls -> ERRO: #{error}") if error

          if existe
            params.url = urls[index]
            Download.exec(params, is_feed: true)
            return

          index++
          @exec(params, urls, index) if urls[index]
      next: ->
        return unless @fila.length
        item = @fila.shift()
        @exec(item.params, item.urls, item.index)
    setTimerToSaveDataJson: ->
      # para nao salvar o @data varias vezes, podendo quebrar o json
      @clearTimerToSaveDataJson()
      @timerToSaveDataJson = setTimeout ->
        ctrl.saveDataJson()
      , 1000 * 10 # 10 segundos
    clearTimerToSaveDataJson: ->
      clearTimeout @timerToSaveDataJson if @timerToSaveDataJson
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'feeds.json', dados, (error)->
          return global.logs.create("Feeds -> saveDataJson -> ERRO: #{error}") if error
          console.info 'Feeds -> feeds.json salvo com sucesso!'
      catch e
        global.logs.create("Feeds -> saveDataJson -> ERRO: #{e}")
      return
    getDataOffline: ->
      console.info 'Feeds -> Pegando feeds de feeds.json'
      try
        @data = JSON.parse(fs.readFileSync('feeds.json', 'utf8') || '{}')
      catch e
        global.logs.create("Feeds -> getDataOffline -> ERRO: #{e}")
    getImageUol: (feedObj, image)->
      tamanhos   = ['1024x551', '900x506', '956x500', '450x450', '450x600']
      opcoesURLs = []

      opcoesURLs.push image.url.replace(/142x100/, item) for item in tamanhos
      opcoesURLs.push image.url
      @verificarUrls.exec feedObj, opcoesURLs
    getImageInfomoney: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.create("Feeds -> getImageInfomoney -> ERRO: #{error}") if error

        data = body.toString()
        imageURL = data.match(/article-col-image(\W+)<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i)?[3] || ''
        return console.warn 'Feeds -> não encontrado imagem de InfoMoney!' unless imageURL

        image = ctrl.mountImageData(params, imageURL)
        feedObj.url  = image.url
        feedObj.nome = image.nome
        Download.exec(feedObj, is_feed: true)

        ctrl.data[params.fonte] ||= {}
        ctrl.data[params.fonte][params.categoria] ||= []
        ctrl.data[params.fonte][params.categoria].push feedObj
      return
    deleteOldImages: ->
      @getDataOffline()
      return if Object.empty(@data || {})

      imagensAtuais = []
      for fonte, categorias of @data
        for categoria, items of categorias || []
          imagensAtuais.push "-name '#{item.nome}'" for item in items || []
      return if imagensAtuais.empty()

      caminho = global.configPath + 'downloads/feeds/'
      command = "find #{caminho} -type f ! \\( #{imagensAtuais.join(' -o ')} \\) -delete"
      shell.exec command, (code, out, error)->
        return global.logs.create("Feeds -> deleteOldImages -> ERRO: #{error}") if error
        global.logs.create('Feeds -> Imagens antigas APAGADAS!')
      return

  global.feeds = ctrl
