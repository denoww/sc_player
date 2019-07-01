data =
  body:    undefined
  loaded:  false
  loading: true

  grade:
    data:
      cor: 'black'
      layout: 'layout-2'
      weather: {}

  feeds:
    data: {}

  timeline:
    conteudos: []
    mensagens: []
    musicas:   []
    transicao:
      conteudos: false
      mensagens: false
      musicas:   false
    current:
      conteudos: {}
      mensagens: {}
      musicas:   {}

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
      vm.grade.data = @data
      timeline.init()

    error = (resp)=>
      @loading = false
      timeline.init()
      console.error 'Grade:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Grade: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Grade: Tentando em #{@tentarNovamenteEm} segundos"
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

feeds =
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
      timeline.init()

    error = (resp)=>
      @loading = false
      timeline.init()
      console.error 'Feeds:', resp

      @tentativas++
      if @tentativas > @tentar
        console.error 'Feeds: Não foi possível comunicar com o servidor!'
        return

      @tentarNovamenteEm = 1000 * @tentativas
      console.warn "Feeds: Tentando em #{@tentarNovamenteEm} segundos"
      setTimeout (-> feeds.get()), @tentarNovamenteEm
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

timeline =
  tipos:     ['conteudos', 'musicas', 'mensagens']
  current:   {}
  promessa:  {}
  nextIndex: {}
  transicao: {}
  playlistIndex: {}
  init: ->
    return unless vm.loaded

    for tipo in @tipos
      @nextIndex[tipo] ||= 0
      @executar(tipo) unless @promessa?[tipo]?
  executar: (tipo)->
    @transicao[tipo] = false
    clearTimeout @promessa[tipo] if @promessa?[tipo]

    vm.timeline.current[tipo] = @getNextItem(tipo)
    return unless vm.timeline.current[tipo]

    segundos = (vm.timeline.current[tipo].segundos * 1000) || 5000
    vm.timeline.transicao[tipo] = true

    setTimeout (-> vm.timeline.transicao[tipo] = false) , 250
    setTimeout (-> vm.timeline.transicao[tipo] = true), segundos - 250
    @promessa[tipo] = setTimeout (-> timeline.executar(tipo)) , segundos
    @playVideo() if vm.timeline.current[tipo].is_video
    return
  playVideo: (tipo)->
    setTimeout ->
      video = document.getElementById('video-player')
      video.play() if video?.paused
    return
  getNextItem: (tipo)->
    lista = (vm.grade.data[tipo] || []).select (e)-> e.ativado
    return unless lista.length

    index = @nextIndex[tipo]
    index = 0 if index >= lista.length

    @nextIndex[tipo]++
    @nextIndex[tipo] = 0 if @nextIndex[tipo] >= lista.length

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
    feeds.nextIndex[fonte] ||= {}

    if !feeds.nextIndex[fonte][categ]?
      feeds.nextIndex[fonte][categ] = 0
    else
      feeds.nextIndex[fonte][categ]++

    if feeds.nextIndex[fonte][categ] >= feedItems.length
      feeds.nextIndex[fonte][categ] = 0

    feedIndex = feeds.nextIndex[fonte][categ]

    feed = feedItems[feedIndex] || feedItems[0]

    return unless feed
    currentItem.nome   = feed.nome
    currentItem.data   = feed.data
    currentItem.titulo = feed.titulo
    currentItem.titulo_feed = feed.titulo_feed

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

relogio =
  exec: ->
    now = new Date
    hour = now.getHours()
    min  = now.getMinutes()
    sec  = now.getSeconds()

    hour = "#{hour}".rjust(2, '0')
    min  = "#{min}".rjust(2, '0')
    sec  = "#{sec}".rjust(2, '0')

    @elemHora ||= document.getElementById('hora')
    @elemHora.innerHTML = hour + ':' + min + ':' + sec if @elemHora
    setTimeout relogio.exec, 1000
    return

vm = new Vue
  el:   '#main-player'
  data: data
  methods:
    mouse: ->
      clearTimeout(@mouseTimeout) if @mouseTimeout
      @body ||= document.getElementById('body-player')
      @body.style.cursor = 'default'

      @mouseTimeout = setTimeout =>
        @body.style.cursor = 'none'
      , 1000
  computed:
    now: -> Date.now()
  created: ->
    @loading = true
    @mouse()
    relogio.exec()

    grade.get ->
      feeds.get ->
        vm.loading = false
        vm.loaded = true

    setInterval ->
      grade.get ->
        feeds.get ->
          vm.loading = false
          vm.loaded = true
    , 1000 * 60 # a cada minuto

  mounted: ->

Vue.filter 'formatDate', (value)->
  moment(value).format('LL') if value

Vue.filter 'formatWeek', (value)->
  moment(value).format('dddd') if value

Vue.filter 'currency', (value)->
  (value || 0).toLocaleString('pt-Br', maximumFractionDigits: 2)
