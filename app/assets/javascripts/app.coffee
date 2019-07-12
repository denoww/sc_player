data =
  body:    undefined
  loaded:  false
  loading: true

  currentIndex: 0

  playlist: []

  grade:
    data:
      cor: 'black'
      layout: 'layout-2'
      weather: {}

  feeds:
    data: {}

  timeline:
    conteudo: {}
    mensagem: {}
    transicao:
      conteudos: false
      mensagens: false

grade =
  data: {}
  tentar: 10
  tentativas: 0
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      @loading    = false
      @tentativas = 0

      @data = resp.data
      onSuccess?()
      @mountWeatherData()
      @handle @data
      timelineConteudos.init()
      timelineMensagens.init()

    error = (resp)=>
      @loading = false
      timelineConteudos.init()
      timelineMensagens.init()
      console.error 'Grade:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Grade: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Grade: Tentando em #{@tentarNovamenteEm / 1000} segundos"
      setTimeout (-> grade.get()), @tentarNovamenteEm
      onError?()

    Vue.http.get('/grade').then success, error
    return
  mountWeatherData: ->
    return unless @data.weather

    dataHoje = new Date
    dia = "#{dataHoje.getDate()}".rjust(2, '0')
    mes = "#{dataHoje.getMonth() + 1}".rjust(2, '0')
    dataHoje = "#{dia}/#{mes}"

    dia = @data.weather.proximos_dias[0]
    if dia.data == dataHoje
      dia = @data.weather.proximos_dias.shift()
      @data.weather.max = dia.max
      @data.weather.min = dia.min

    @data.weather.proximos_dias = @data.weather.proximos_dias.slice(0,4)
    return
  handle: (data)->
    dados = @data
    dados.conteudos = (dados?.conteudos || []).select (e)-> e.ativado
    dados.mensagens = (dados?.mensagens || []).select (e)-> e.ativado
    dados.musicas   = (dados?.musicas || []).select (e)-> e.ativado
    vm.grade.data = dados
    return

feedsObj =
  data: {}
  tentar: 10
  tentativas: 0
  nextIndex: {}
  get: (onSuccess, onError)->
    return if @loading
    @loading = true

    success = (resp)=>
      @loading    = false
      @tentativas = 0

      @data = resp.data
      @verificarNoticias()
      onSuccess?()
      vm.feeds.data = @data
      timelineConteudos.init()
      timelineMensagens.init()

    error = (resp)=>
      @loading = false
      timelineConteudos.init()
      timelineMensagens.init()
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
  verificarNoticias: ->
    for fonte, categorias of @data
      for categoria, valores of categorias
        if (valores || []).empty()
          return unless grade.data.conteudos
          conteudos = grade.data.conteudos.select (e)->
            e.fonte == fonte && e.categoria == categoria
          cont.ativado = false for cont in conteudos
    return

timelineConteudos =
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

    vm.currentIndex = vm.playlist.getIndexByField 'id', itemAtual.id
    if !vm.currentIndex?
      vm.playlist.push itemAtual
      vm.currentIndex = vm.playlist.length - 1

    @stopUltimoVideo()

    segundos = (itemAtual.segundos * 1000) || 5000
    @promessa = setTimeout ->
      itemAtual.active = false
      timelineConteudos.executar()
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
    lista = vm.grade.data.conteudos
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
    feedItems = vm.feeds.data[currentItem.fonte]?[currentItem.categoria]
    return currentItem if (feedItems || []).empty()

    fonte = currentItem.fonte
    categ = currentItem.categoria
    feedsObj.nextIndex[fonte] ||= {}

    if !feedsObj.nextIndex[fonte][categ]?
      feedsObj.nextIndex[fonte][categ] = 0
    else
      feedsObj.nextIndex[fonte][categ]++

    if feedsObj.nextIndex[fonte][categ] >= feedItems.length
      feedsObj.nextIndex[fonte][categ] = 0

    feedIndex = feedsObj.nextIndex[fonte][categ]

    feed = feedItems[feedIndex] || feedItems[0]

    return unless feed
    currentItem.id     = "#{currentItem.id}#{feed.nome_arquivo}"
    currentItem.data   = feed.data
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed
    currentItem.nome_arquivo = feed.nome_arquivo
    currentItem
  getItemPlaylist: (playlist)->
    if !@playlistIndex[playlist.id]?
      @playlistIndex[playlist.id] = 0
    else
      @playlistIndex[playlist.id]++

    if @playlistIndex[playlist.id] >= playlist.conteudos.length
      @playlistIndex[playlist.id] = 0

    currentItem = playlist.conteudos[@playlistIndex[playlist.id]]

    return currentItem if currentItem.tipo_midia != 'feed'
    @getItemFeed(currentItem)

timelineMensagens =
  current:   {}
  promessa:  null
  nextIndex: 0
  init: ->
    return unless vm.loaded
    @executar() unless @promessa?
  executar: ->

    clearTimeout @promessa if @promessa

    vm.timeline.mensagem = @getNextItem()
    return unless vm.timeline.mensagem

    segundos = (vm.timeline.mensagem.segundos * 1000) || 5000
    @promessa = setTimeout (-> timelineMensagens.executar()), segundos
    return
  getNextItem: ->
    lista = vm.grade.data.mensagens
    total = lista.length
    return unless total

    index = @nextIndex
    index = 0 if index >= total

    @nextIndex++
    @nextIndex = 0 if @nextIndex >= total

    lista[index]

relogio =
  exec: ->
    now = new Date
    hour = now.getHours()
    min  = now.getMinutes()
    sec  = now.getSeconds()

    hour = "0#{hour}" if hour < 10
    min  = "0#{min}"  if min < 10
    sec  = "0#{sec}"  if sec < 10

    @elemHora ||= document.getElementById('hora')
    @elemHora.innerHTML = hour + ':' + min + ':' + sec if @elemHora
    setTimeout relogio.exec, 1000
    return

vm = new Vue
  el:   '#main-player'
  data: data
  methods:
    playVideo: timelineConteudos.playVideo
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
      grade.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000

    setInterval ->
      grade.get ->
        feedsObj.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 60 # a cada minuto

Vue.filter 'formatDate', (value)->
  moment(value).format('DD MMM') if value

Vue.filter 'formatWeek', (value)->
  moment(value).format('dddd') if value

Vue.filter 'currency', (value)->
  (value || 0).toLocaleString('pt-Br', minimumFractionDigits: 2, maximumFractionDigits: 2)
