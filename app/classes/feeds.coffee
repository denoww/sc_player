fs        = require 'fs'
md5       = require 'md5'
RSS       = require 'rss-parser'
path      = require 'path'
shell     = require 'shelljs'
request   = require 'request'
UrlExists = require 'url-exists'

module.exports = ->
  ctrl =
    data: {}
    totalItensPorCategoria: 15
    getList: ->
      feeds = []
      posicoes = ['conteudo_superior', 'conteudo_mensagem']
      @getDataOffline()

      for posicao in posicoes
        continue unless global.grade?.data?[posicao]?.length
        for feed in global.grade.data[posicao].select (item)-> item.tipo_midia == 'feed'
          feeds.addOrExtend feed
        playlists = global.grade.data[posicao].select (item)-> item.tipo_midia == 'playlist'

        for playlist in playlists
          for feed in playlist[posicao].select (item)-> item.tipo_midia == 'feed'
            feeds.addOrExtend feed

      return if feeds.empty()
      @baixarFeeds(feed) for feed in feeds
    baixarFeeds: (params)->
      return if global.grade?.data?.offline
      parserRSS = new RSS(defaultRSS: 2.0)

      parserRSS.parseURL params.url,
      (error, feeds)=>
        return global.logs.error "Feeds -> baixarFeeds #{error}" if error
        return if (feeds.items || []).empty()

        @data[params.fonte] ||= {}
        @data[params.fonte][params.categoria] ||= []
        @handlelist(params, feed) for feed in feeds.items.splice(0, @totalItensPorCategoria)
        @setTimerToSaveDataJson()
      return
    handlelist: (params, feed)->
      imageObj = @getImageData(params, feed)
      return unless imageObj

      feedObj =
        url:          imageObj.url
        data:         feed.isoDate
        titulo:       feed.title
        titulo_feed:  params.titulo
        nome_arquivo: imageObj.nome_arquivo

      switch params.fonte
        when 'uol'
          return @getImageUol(params, feedObj, imageObj.url) if imageObj.url?.match?(/uol.+\d{3}x\d{3}/)
        when 'infomoney'
          return @getImageInfomoney(params, feedObj, imageObj.url) if imageObj.no_image
        when 'bbc'
          return @getImageBbc(params, feedObj, imageObj.url) if imageObj.no_image
        when 'o_globo'
          return @getImageOGlobo(params, feedObj, imageObj.url) if imageObj.no_image
      @addToData(params, feedObj)
    addToData: (params, feedObj)->
      Download.exec(feedObj, is_feed: true)

      @data[params.fonte] ||= {}
      dataFeeds = @data[params.fonte][params.categoria] || []

      dataFeeds.unshift feedObj
      dataFeeds = dataFeeds.slice 0, @totalItensPorCategoria
      @data[params.fonte][params.categoria] = dataFeeds
    getImageData: (params, feed)->
      if feed.enclosure?.url && feed.enclosure?.type?.match(/image/)
        return @mountImageData(params, feed.enclosure.url)

      # pegando o src da imagem
      regexImg   = /<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i
      imageURL   = (feed.content || '').replace(/\n|\r\n/g, '').match(regexImg)?[2] || ''
      imageURL ||= (feed['content:encoded'] || '').replace(/\n|\r\n/g, '').match(regexImg)?[2] || ''

      # substituindo &amp; por &
      imageURL = imageURL.replace(/(&amp;|amp;)+/g, '&')

      # removendo dimensions e resize para pegar a imagem com mais qualidade
      imageURL = imageURL.replace(/(dimensions=(\d+x\d+)|resize=(\d+x\d+))\W?/gi, '')

      # se eh uma imagem externa vamos pegar direto da fonte
      if imageURL.match(/\/external_images\?/i) && imageURL.match(/url=/i)
        imageURL = imageURL.match(/url=(.*)$/i)?[1] || imageURL

      switch params.fonte
        when 'infomoney'
          return url: feed.link, no_image: true if !imageURL
          imageURL = imageURL.match(/(.*)[?]/)?[1]
        when 'bbc'
          return url: feed.link, no_image: true if !imageURL
        when 'o_globo'
          return url: feed.link, no_image: true if !imageURL

      return unless imageURL
      @mountImageData(params, imageURL)
    mountImageData: (params, url)->
      extension = url.match(/\.jpg|\.jpeg|\.png|\.gif|\.webp/i)?[0] || ''
      imageNome = url.split('/').pop().replace(extension, '').removeSpecialCharacters()
      imageNome = "#{params.fonte}-#{params.categoria}-#{md5(imageNome)}"
      imageNome = "#{imageNome}#{extension}"

      url: url, nome_arquivo: imageNome
    verificarUrls:
      fila: []
      exec: (params, feedObj, urls, index=0)->
        return @fila.push params: params, feedObj: feedObj, urls: urls, index: index if @loading
        @loading = true

        UrlExists urls[index], (error, existe)=>
          @loading = false
          @next()
          return global.logs.error "Feeds -> verificarUrls #{error}" if error

          if existe
            feedObj.url = urls[index]
            Download.exec(feedObj, is_feed: true)
            ctrl.addToData(params, feedObj)
            return

          index++
          @exec(params, feedObj, urls, index) if urls[index]
      next: ->
        return ctrl.setTimerToSaveDataJson(1) unless @fila.length
        item = @fila.shift()
        @exec(item.params, item.feedObj, item.urls, item.index)
    setTimerToSaveDataJson: (time=10)->
      # para nao salvar o @data varias vezes, podendo quebrar o json
      @clearTimerToSaveDataJson()
      @timerToSaveDataJson = setTimeout ->
        ctrl.saveDataJson()
      , 1000 * time # default 10 segundos
    clearTimerToSaveDataJson: ->
      clearTimeout @timerToSaveDataJson if @timerToSaveDataJson
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'feeds.json', dados, (error)->
          return global.logs.error "Feeds -> saveDataJson #{error}" if error
          global.logs.create 'Feeds -> feeds.json salvo com sucesso!'
      catch e
        global.logs.error "Feeds -> saveDataJson #{e}"
      return
    getDataOffline: ->
      console.info 'Feeds -> Pegando feeds de feeds.json'
      try
        @data = JSON.parse(fs.readFileSync('feeds.json', 'utf8') || '{}')
      catch e
        global.logs.error "Feeds -> getDataOffline #{e}"
    getImageUol: (params, feedObj, url)->
      # tenta encontrar outros tamanhos de imagem disponibilizadas pelo uol
      tamanhos   = ['1024x551', '900x506', '956x500', '615x300', '450x450', '450x600']
      opcoesURLs = []

      opcoesURLs.push url.replace(/\d{3}x\d{3}/, tam) for tam in tamanhos
      opcoesURLs.push url
      @verificarUrls.exec params, feedObj, opcoesURLs
    getImageInfomoney: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.error "Feeds -> getImageInfomoney #{error}" if error

        data = body.toString()
        # imageURL = data.match(/article-col-image(\W+)<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i)?[3] || '' # OLD VERSION
        imageURL = data.match(/figure(.|\n)*?<(\s+)?img(?:.*\ssrc=["'](.*?)["'].*)\/>?/i)?[3] || ''
        return console.warn 'Feeds -> não encontrado imagem de InfoMoney!' unless imageURL

        imageURL             = imageURL.match(/(.*)[?]/)?[1]
        image                = ctrl.mountImageData(params, imageURL)
        feedObj.url          = image.url
        feedObj.nome_arquivo = image.nome_arquivo
        ctrl.addToData(params, feedObj)
      return
    getImageBbc: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.error "Feeds -> getImageBbc #{error}" if error

        data       = body.toString().replace(/\n|\s|\r\n|\r/g, '')
        imageURL   = data.match(/story-body__inner.+?figure.+?<img.+?src=["'](.+?)["']/i)?[1] || ''
        imageURL ||= data.match(/gallery-images.+?gallery-images__image.+?<img.+?src=["'](.+?)["']/i)?[1] || ''
        imageURL ||= data.match(/<metaproperty="og:image"content="(.+?)"/i)?[1] || ''
        return console.warn 'Feeds -> não encontrado imagem de BBC!' unless imageURL

        imageURL = imageURL.replace(/news\/(\d+)\/cpsprodpb/, 'news/1024/cpsprodpb')
        imageURL = imageURL.replace(/news\/(\d+)\/branded_portuguese/, 'news/1024/cpsprodpb')

        image                = ctrl.mountImageData(params, imageURL)
        feedObj.url          = image.url
        feedObj.nome_arquivo = image.nome_arquivo
        ctrl.addToData(params, feedObj)
      return
    getImageOGlobo: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.error "Feeds -> getImageOGlobo #{error}" if error

        data     = body.toString().replace(/\n|\s|\r\n|\r/g, '')
        imageURL = data.match(/figure.+?article-header__picture.+?<img.+?article__picture-image.+?src=["'](.+?)["']/i)?[1] || ''
        return console.warn 'Feeds -> não encontrado imagem de O Globo!' unless imageURL

        image                = ctrl.mountImageData(params, imageURL)
        feedObj.url          = image.url
        feedObj.nome_arquivo = image.nome_arquivo
        ctrl.addToData(params, feedObj)
      return
    deleteOldImages: ->
      @getDataOffline()
      return if Object.empty(@data || {})

      imagensAtuais = []
      for fonte, categorias of @data
        for categoria, items of categorias || []
          imagensAtuais.push "-name '#{item.nome_arquivo}'" for item in items || []
      return if imagensAtuais.empty()

      caminho = global.configPath + 'downloads/feeds/'
      command = "find #{caminho} -type f ! \\( #{imagensAtuais.join(' -o ')} \\) -delete"
      shell.exec command, (code, out, error)->
        return global.logs.error "Feeds -> deleteOldImages #{error}" if error
        global.logs.info 'Feeds -> Imagens antigas APAGADAS!'
        return
      return

  global.feeds = ctrl
