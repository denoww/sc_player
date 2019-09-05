{ crashReporter } = require 'electron'
crashReporter.start
  productName: 'sc_player'
  companyName: 'seucondominioWeb'
  submitURL: 'https://sentry.io/api/1519364/minidump/?sentry_key=ac78f87fac094b808180f86ad8867f61'
  autoSubmit: true

Sentry.init
  dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
  integrations: [new Sentry.Integrations.Vue({Vue, attachProps: true})]

data =
  body:    undefined
  loaded:  false
  loading: true

  indexConteudoSuperior: 0
  indexConteudoMensagem: 0

  listaConteudoSuperior: []
  listaConteudoMensagem: []

  grade:
    data:
      cor: 'black'
      layout: 'layout-2'
      weather: {}

onLoaded = ->
  timelineConteudoSuperior.init()
  timelineConteudoMensagem.init()

gradeObj =
  tentar: 10
  tentativas: 0
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      @loading    = false
      @tentativas = 0

      @handle resp.data
      onSuccess?()
      @mountWeatherData()
      onLoaded()

    error = (resp)=>
      @loading = false
      onLoaded()
      console.error 'Grade:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Grade: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Grade: Tentando em #{@tentarNovamenteEm / 1000} segundos"
      setTimeout (-> gradeObj.get()), @tentarNovamenteEm
      onError?()

    Vue.http.get('/grade').then success, error
    return
  handle: (data)->
    @data = data
    vm.grade.data = data
    return
  mountWeatherData: ->
    return unless @data.weather

    dataHoje = new Date
    dia = "#{dataHoje.getDate()}".rjust(2, '0')
    mes = "#{dataHoje.getMonth() + 1}".rjust(2, '0')
    dataHoje = "#{dia}/#{mes}"

    dia = @data.weather.proximos_dias?[0]
    if dia.data == dataHoje
      dia = @data.weather.proximos_dias.shift()
      @data.weather.max = dia.max
      @data.weather.min = dia.min

    @data.weather.proximos_dias = @data.weather.proximos_dias.slice(0,4)
    return

feedsObj =
  data: {}
  tentar: 10
  tentativas: 0
  posicoes: ['conteudo_superior', 'conteudo_mensagem']
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      @loading    = false
      @tentativas = 0

      @handle(resp.data)
      @verificarNoticias()
      onSuccess?()
      onLoaded()

    error = (resp)=>
      @loading = false
      onLoaded()
      console.error 'Feeds:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Feeds: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Feeds: Tentando em #{@tentarNovamenteEm / 1000} segundos"
      setTimeout (-> feedsObj.get()), @tentarNovamenteEm
      onError?()

    Vue.http.get('/feeds').then success, error
    return
  handle: (data)->
    @data = data
    # pre-montar a estrutura dos feeds com base na grade para ser usado em verificarNoticias()
    for posicao in @posicoes
      feeds = vm.grade.data[posicao].select (e)-> e.tipo_midia == 'feed'

      for feed in feeds
        @data[feed.fonte] ||= {}
        @data[feed.fonte][feed.categoria] ||= []
    return
  verificarNoticias: ->
    # serve para remover feeds que nao tem noticias
    for fonte, categorias of @data
      for categoria, noticias of categorias
        if (noticias || []).empty()
          for posicao in @posicoes
            continue unless vm.grade.data[posicao]

            items = vm.grade.data[posicao].select (e)->
              e.fonte == fonte && e.categoria == categoria
            vm.grade.data[posicao].removeById item.id for item in items
    return

timelineConteudoSuperior =
  promessa:  null
  nextIndex: 0
  feedIndex: {}
  playlistIndex: {}
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->
    clearTimeout @promessa if @promessa

    itemAtual = @getNextItem()
    return unless itemAtual

    vm.indexConteudoSuperior = vm.listaConteudoSuperior.getIndexByField 'id', itemAtual.id
    if !vm.indexConteudoSuperior?
      vm.listaConteudoSuperior.push itemAtual
      vm.indexConteudoSuperior = vm.listaConteudoSuperior.length - 1

    @stopUltimoVideo()

    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout ->
      timelineConteudoSuperior.executar()
    , segundos

    @playVideo(itemAtual) if itemAtual.is_video
    return
  playVideo: (itemAtual)->
    @ultimoVideo = "video-player-#{itemAtual.id}"

    setTimeout =>
      video = document.getElementById(@ultimoVideo)
      if video
        video.currentTime = 0
        video.play()

    setTimeout =>
      video = document.getElementById(@ultimoVideo)
      video.play() if video?.paused
    , 1000
    return
  stopUltimoVideo: ->
    videoId = @ultimoVideo
    return unless videoId

    video = document.getElementById(videoId)
    video.pause() if video
    @ultimoVideo = null
    return
  getNextItem: ->
    lista = vm.grade.data.conteudo_superior
    total = lista.length
    return unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    currentItem = lista[index]
    switch currentItem.tipo_midia
      when 'feed'     then @getItemFeed(currentItem)
      when 'playlist' then @getItemPlaylist(currentItem)
      else currentItem
  getItemFeed: (currentItem)->
    feedItems = feedsObj.data[currentItem.fonte]?[currentItem.categoria] || []
    return currentItem if feedItems.empty()

    fonte = currentItem.fonte
    categ = currentItem.categoria
    @feedIndex[fonte] ||= {}

    if !@feedIndex[fonte][categ]?
      @feedIndex[fonte][categ] = 0
    else
      @feedIndex[fonte][categ]++

    if @feedIndex[fonte][categ] >= feedItems.length
      @feedIndex[fonte][categ] = 0

    index = @feedIndex[fonte][categ]
    feed = feedItems[index] || feedItems[0]

    return unless feed
    currentItem.id     = "#{currentItem.id}#{feed.nome_arquivo}"
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed
    currentItem.nome_arquivo = feed.nome_arquivo
    currentItem
  getItemPlaylist: (playlist)->
    if !@playlistIndex[playlist.id]?
      @playlistIndex[playlist.id] = 0
    else
      @playlistIndex[playlist.id]++

    if @playlistIndex[playlist.id] >= playlist.conteudo_superior.length
      @playlistIndex[playlist.id] = 0

    currentItem = playlist.conteudo_superior[@playlistIndex[playlist.id]]

    return currentItem if currentItem.tipo_midia != 'feed'
    @getItemFeed(currentItem)

timelineConteudoMensagem =
  promessa:  null
  nextIndex: 0
  playlistIndex: {}
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->
    clearTimeout @promessa if @promessa

    itemAtual = @getNextItem()
    return unless itemAtual

    vm.indexConteudoMensagem = vm.listaConteudoMensagem.getIndexByField 'id', itemAtual.id
    if !vm.indexConteudoMensagem?
      vm.listaConteudoMensagem.push itemAtual
      vm.indexConteudoMensagem = vm.listaConteudoMensagem.length - 1

    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout ->
      timelineConteudoMensagem.executar()
    , segundos
    return
  getNextItem: ->
    lista = vm.grade.data.conteudo_mensagem
    total = lista.length
    return unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    currentItem = lista[index]
    switch currentItem.tipo_midia
      when 'feed' then @getItemFeed(currentItem)
      else currentItem
  getItemFeed: (currentItem)->
    feedItems = feedsObj.data[currentItem.fonte]?[currentItem.categoria] || []
    return currentItem if feedItems.empty()

    index = parseInt(Math.random() * 100) % feedItems.length
    feed = feedItems[index] || feedItems[0]

    return unless feed
    currentItem.id     = "#{currentItem.id}#{feed.titulo}"
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed
    currentItem

relogio =
  exec: ->
    now = new Date
    hour = now.getHours()
    min  = now.getMinutes()
    # sec  = now.getSeconds()

    hour = "0#{hour}" if hour < 10
    min  = "0#{min}"  if min < 10
    # sec  = "0#{sec}"  if sec < 10

    @elemHora ||= document.getElementById('hora')
    @elemHora.innerHTML = hour + ':' + min if @elemHora
    @timer = setTimeout relogio.exec, 1000 * 60 # 1 minuto
    # @elemHora.innerHTML = hour + ':' + min + ':' + sec if @elemHora
    # setTimeout relogio.exec, 1000
    return

vm = new Vue
  el:   '#main-player'
  data: data
  methods:
    playVideo: timelineConteudoSuperior.playVideo
    mouse: ->
      clearTimeout(@mouseTimeout) if @mouseTimeout
      @body ||= document.getElementById('body-player')
      @body.style.cursor = 'default'

      @mouseTimeout = setTimeout =>
        @body.style.cursor = 'none'
      , 1000
  computed:
    now: -> Date.now()
  mounted: ->
    @loading = true
    @mouse()
    relogio.exec()

    setTimeout ->
      return if vm.loaded
      gradeObj.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 5 # 5 segundos

    setInterval ->
      gradeObj.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 60 * 2 # a cada 2 minutos

Vue.filter 'formatDate', (value)->
  moment(value).format('DD MMM') if value

Vue.filter 'formatWeek', (value)->
  moment(value).format('dddd') if value

Vue.filter 'currency', (value)->
  (value || 0).toLocaleString('pt-Br', minimumFractionDigits: 2, maximumFractionDigits: 2)
