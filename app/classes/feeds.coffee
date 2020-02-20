fs        = require 'fs'
md5       = require 'md5'
RSS       = require 'rss-parser'
path      = require 'path'
shell     = require 'shelljs'
QRCode    = require 'qrcode'
moment    = require 'moment'
request   = require 'request'
UrlExists = require 'url-exists'

module.exports = ->
  ctrl =
    data: {}
    diasDataMinima: -14
    totalItensPorCategoria: 15
    getList: ->
      feeds = []
      posicoes = ['conteudo_superior', 'conteudo_mensagem']
      @dataMinima = moment().add(@diasDataMinima, 'days')
      @getDataOffline()
      return if global.grade?.data?.offline

      for posicao in posicoes
        continue unless global.grade?.data?[posicao]?.length
        for feed in global.grade.data[posicao].select (item)-> item.tipo_midia == 'feed'
          feeds.addOrExtend feed
        playlists = global.grade.data[posicao].select (item)-> item.tipo_midia == 'playlist'

        for playlist in playlists
          for feed in playlist[posicao].select (item)-> item.tipo_midia == 'feed'
            feeds.addOrExtend feed

      return if feeds.empty()
      for params in feeds
        switch params.fonte
          when 'canaltech' then @baixarCanaltech(params)
          else @baixarFeeds(params)
      @sanitizarFeedsJson(feeds)
    baixarFeeds: (params)->
      parserRSS = new RSS
        defaultRSS: 2.0
        customFields: item: ['mediaurl', 'media:content']

      parserRSS.parseURL params.url, (error, feeds)=>
        return global.logs.create "Feeds -> baixarFeeds #{error}" if error
        @handleFonte(params, feeds.items)
      return
    baixarCanaltech: (params)->
      request params.url, (error, resp, body)=>
        return global.logs.error "Feeds -> baixarCanaltech #{error}", tags: class: 'feeds' if error
        return global.logs.create "Feeds -> baixarCanaltech Error: #{resp.statusCode}" if resp.statusCode != 200

        try
          jsonData = JSON.parse body
          @handleFonte(params, jsonData?.items)
        catch e
          global.logs.error "Feeds -> baixarCanaltech #{e}", tags: class: 'feeds'
      return
    handleFonte: (params, feeds)->
      return if (feeds || []).empty()

      @data[params.fonte] ||= {}
      @data[params.fonte][params.categoria] ||= []

      keyData = 'data'
      keyData = 'isoDate' if feeds[0].isoDate

      for feed in feeds.sortByField(keyData, 'desc').splice(0, @totalItensPorCategoria)
        # somente noticias de ate 2 semanas atras
        data = feed.isoDate || feed.data
        continue unless data

        @handleFeed(params, feed) if moment(data) >= @dataMinima
      @setTimerToSaveDataJson()
    handleFeed: (params, feed)->
      imageObj = @getImageData(params, feed)
      return unless imageObj

      if params.categoria == 'todas_noticias'
        categoriaFeed = feed.categoria

      feedObj =
        id:             md5 imageObj.url
        url:            imageObj.url
        data:           feed.isoDate || feed.data
        link:           feed.link
        titulo:         feed.title || feed.titulo
        titulo_feed:    params.titulo
        nome_arquivo:   imageObj.nome_arquivo
        categoria_feed: categoriaFeed

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

      addData = ->
        dataFeeds.addOrExtend feedObj
        dataFeeds = dataFeeds.sortByField 'data', 'desc'
        dataFeeds = dataFeeds.slice 0, ctrl.totalItensPorCategoria
        ctrl.data[params.fonte][params.categoria] = dataFeeds

      return addData() if feedObj.qrcode
      @createQRCode feedObj, addData
    createQRCode: (feedObj, callback)->
      QRCode.toDataURL feedObj.link, (error, dataUrl)->
        global.logs.error "Feeds -> createQRCode #{error}", tags: class: 'feeds' if error
        feedObj.qrcode = dataUrl
        callback?()
      return
    getImageData: (params, feed)->
      if feed.enclosure?.url && feed.enclosure?.type?.match(/image/)
        return @mountImageData(params, feed.enclosure.url)

      if feed.imagem
        return @mountImageData(params, feed.imagem)

      if feed.mediaurl
        return @mountImageData(params, feed.mediaurl)

      if feed['media:content']?['$']?.url && feed['media:content']?['$']?.medium == 'image'
        return @mountImageData(params, feed['media:content']['$'].url)

      # pegando o src da imagem
      # regexImg   = /<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i
      regexImg   = /<(\s+)?(?:img|amp-img)(?:.+?src=["'](.*?)["'].*)/i
      imageURL   = (feed.content || '').replace(/\t|\n|\r\n/g, '').match(regexImg)?[2] || ''
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

      return if !imageURL || !Download.validURL(imageURL)
      @mountImageData(params, imageURL)
    mountImageData: (params, url)->
      # extension = url.match(/\.jpg|\.jpeg|\.png|\.gif|\.svg|\.webp/i)?[0] || ''
      # imageNome = url.split('/').pop().replace(extension, '').removeSpecialCharacters()
      imageNome = "#{params.fonte}-#{params.categoria}-#{md5(url)}"
      imageNome = "#{imageNome}.webp"
      # imageNome = "#{imageNome}#{extension}"

      url: url, nome_arquivo: imageNome
    verificarUrls:
      fila: []
      exec: (params, feedObj, urls, index=0)->
        return @fila.push params: params, feedObj: feedObj, urls: urls, index: index if @loading
        @loading = true

        UrlExists urls[index], (error, existe)=>
          @loading = false
          @next()
          return global.logs.error "Feeds -> verificarUrls #{error}", tags: class: 'feeds' if error

          if existe
            feedObj.url = urls[index]
            Download.exec(feedObj, is_feed: true)
            ctrl.addToData(params, feedObj)
            return

          index++
          @exec(params, feedObj, urls, index) if urls[index]
      next: ->
        return ctrl.setTimerToSaveDataJson(5) unless @fila.length
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
    sanitizarFeedsJson: (feeds)->
      newFontes = feeds.map (e)-> e.fonte
      oldFontes = Object.keys @data

      oldFontes.remove newFonte for newFonte in newFontes
      delete @data[oldFonte]    for oldFonte in oldFontes
      return
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'feeds.json', dados, (error)->
          return global.logs.error "Feeds -> saveDataJson #{error}", tags: class: 'feeds' if error
          global.logs.create 'Feeds -> feeds.json salvo com sucesso!'
      catch e
        global.logs.error "Feeds -> saveDataJson #{e}", tags: class: 'feeds'
      return
    getDataOffline: ->
      global.logs.create 'Feeds -> Pegando feeds de feeds.json'
      try
        @data = JSON.parse(fs.readFileSync('feeds.json', 'utf8') || '{}')
      catch e
        global.logs.error "Feeds -> getDataOffline #{e}", tags: class: 'feeds'
    getImageUol: (params, feedObj, url)->
      # tenta encontrar outros tamanhos de imagem disponibilizadas pelo uol
      tamanhos   = ['1024x551', '900x506', '956x500', '615x300', '450x450', '450x600']
      opcoesURLs = []

      opcoesURLs.push url.replace(/\d{3}x\d{3}/, tam) for tam in tamanhos
      opcoesURLs.push url
      @verificarUrls.exec params, feedObj, opcoesURLs
    getImageInfomoney: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.create "Feeds -> getImageInfomoney #{error}", tags: class: 'feeds' if error

        data = body.toString()
        # imageURL = data.match(/article-col-image(\W+)<(\s+)?img(?:.*src=["'](.*?)["'].*)\/>?/i)?[3] || '' # OLD VERSION
        imageURL = data.match(/figure(.|\n)*?<(\s+)?img(?:.*\ssrc=["'](.*?)["'].*)\/>?/i)?[3] || ''
        unless imageURL
          global.logs.create 'Feeds -> não encontrado imagem de InfoMoney!',
            extra: url: url
            tags: class: 'feeds'
          return

        imageURL             = imageURL.match(/(.*)[?]/)?[1]
        image                = ctrl.mountImageData(params, imageURL)
        feedObj.url          = image.url
        feedObj.nome_arquivo = image.nome_arquivo
        ctrl.addToData(params, feedObj)
      return
    getImageBbc: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.create "Feeds -> getImageBbc #{error}", tags: class: 'feeds' if error

        data       = body.toString().replace(/\n|\s|\r\n|\r/g, '')
        imageURL   = data.match(/story-body__inner.+?figure.+?<img.+?src=["'](.+?)["']/i)?[1] || ''
        imageURL = null if imageURL.match /bbc_placeholder/
        imageURL ||= data.match(/story-body__inner.+?js-delayed-image-load.+?data-src=["'](.+?)["']/i)?[1] || ''
        imageURL = null if imageURL.match /bbc_placeholder/
        imageURL ||= data.match(/gallery-images.+?gallery-images__image.+?<img.+?src=["'](.+?)["']/i)?[1] || ''
        imageURL = null if imageURL.match /bbc_placeholder/
        imageURL ||= data.match(/<metaproperty="og:image"content="(.+?)"/i)?[1] || ''
        unless imageURL
          global.logs.create 'Feeds -> não encontrado imagem de BBC!',
            extra: url: url
            tags: class: 'feeds'
          return

        imageURL = imageURL.replace(/news\/(\d+)\/cpsprodpb/, 'news/1024/cpsprodpb')
        imageURL = imageURL.replace(/news\/(\d+)\/branded_portuguese/, 'news/1024/cpsprodpb')

        image                = ctrl.mountImageData(params, imageURL)
        feedObj.url          = image.url
        feedObj.nome_arquivo = image.nome_arquivo
        ctrl.addToData(params, feedObj)
      return
    getImageOGlobo: (params, feedObj, url)->
      request url, (error, res, body)->
        return global.logs.create "Feeds -> getImageOGlobo #{error}", tags: class: 'feeds' if error

        data     = body.toString().replace(/\n|\s|\r\n|\r/g, '')
        imageURL = data.match(/figure.+?article-header__picture.+?<img.+?article__picture-image.+?src=["'](.+?)["']/i)?[1] || ''
        unless imageURL
          global.logs.create 'Feeds -> não encontrado imagem de O Globo!',
            extra: url: url
            tags: class: 'feeds'
          return

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
        return global.logs.error "Feeds -> deleteOldImages #{error}", tags: class: 'feeds' if error
        global.logs.create 'Feeds -> Imagens antigas APAGADAS!'
        return
      return

  global.feeds = ctrl
