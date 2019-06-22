app = angular.module('publicidade_app', ['ngSanitize', 'ngLocale'])

app.config ['$qProvider', ($qProvider)->
    $qProvider.errorOnUnhandledRejections(false)
]

app.controller('MainCtrl', [
  '$http', '$timeout'
  ($http, $timeout)->
    vm = @
    vm.loading = true

    vm.init = ->
      vm.openFullScreen(document.getElementById('body-player'))
      vm.loading = true

      vm.grade.get ->
        vm.feeds.get ->
          vm.loading = false
          vm.loaded = true
          vm.relogio()

      setInterval ->
        vm.grade.get ->
          vm.feeds.get ->
            vm.loading = false
            vm.loaded = true
      , 1000 * 60  # a cada minuto

    vm.timeline =
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
          @executar(tipo) if @promessa?[tipo]?.$$state?.status != 0
      executar: (tipo)->
        @transicao[tipo] = false
        $timeout.cancel(@promessa[tipo]) if @promessa?[tipo]

        @current[tipo] = @getNextItem(tipo)
        return unless @current[tipo]

        segundos = (@current[tipo].segundos * 1000) || 5000
        vm.timeline.transicao[tipo] = true
        $timeout (-> vm.timeline.transicao[tipo] = false), 250
        $timeout (-> vm.timeline.transicao[tipo] = true), segundos - 250
        @promessa[tipo] = $timeout (-> vm.timeline.next(tipo)), segundos
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
        vm.feeds.nextIndex[fonte] ||= {}

        if !vm.feeds.nextIndex[fonte][categ]?
          vm.feeds.nextIndex[fonte][categ] = 0
        else
          vm.feeds.nextIndex[fonte][categ]++

        if vm.feeds.nextIndex[fonte][categ] >= feedItems.length
          vm.feeds.nextIndex[fonte][categ] = 0

        feedIndex = vm.feeds.nextIndex[fonte][categ]

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
      next: (tipo)->
        @current[tipo] = {}
        $timeout -> vm.timeline.executar(tipo)

    vm.grade =
      data: {}
      tentar: 10
      tentativas: 0
      get: (onSuccess, onError)->
        return if @loading
        @loading = true

        success = (resp)=>
          @loading    = false
          @tentativas = 0
          vm.offline  = resp.data.offline

          @data = resp.data
          onSuccess?()
          @mountWeatherData()
          vm.timeline.init()

        error = (resp)=>
          @loading = false
          vm.timeline.init()
          console.error 'Grade:', resp

          @tentativas++
          if @tentativas > @tentar
            console.error 'Grade: Não foi possível comunicar com o servidor!'
            return

          @tentarNovamenteEm = 1000 * @tentativas
          console.warn "Grade: Tentando em #{@tentarNovamenteEm} segundos"
          $timeout (-> vm.grade.get()), @tentarNovamenteEm
          onError?()

        $http(method: 'GET', url: '/grade').then success, error
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
        return

    vm.feeds =
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
          vm.timeline.init()

        error = (resp)=>
          @loading = false
          vm.timeline.init()
          console.error 'Feeds:', resp

          @tentativas++
          if @tentativas > @tentar
            console.error 'Feeds: Não foi possível comunicar com o servidor!'
            return

          @tentarNovamenteEm = 1000 * @tentativas
          console.warn "Feeds: Tentando em #{@tentarNovamenteEm} segundos"
          $timeout (-> vm.feeds.get()), @tentarNovamenteEm
          onError?()

        $http(method: 'GET', url: '/feeds').then success, error
        return
      verificarNoticias: ->
        for fonte, categorias of @data
          for categoria, valores of categorias
            if (valores || []).empty()
              return unless vm.grade.data.conteudos
              conteudos = vm.grade.data.conteudos.select (e)->
                e.fonte == fonte && e.categoria == categoria
              cont.ativado = false for cont in conteudos
        return

    vm.mouse =
      onMove: ->
        $timeout.cancel(@timeout) if @timeout
        document.body.style.cursor = 'default'

        @timeout = $timeout =>
          document.body.style.cursor = 'none'
        , 1000

    vm.relogio = ->
      vm.now = new Date
      hour = vm.now.getHours()
      min  = vm.now.getMinutes()
      sec  = vm.now.getSeconds()

      hour = "#{hour}".rjust(2, '0')
      min  = "#{min}".rjust(2, '0')
      sec  = "#{sec}".rjust(2, '0')

      elem = document.getElementById('hora')
      elem.innerHTML = hour + ':' + min + ':' + sec if elem
      setTimeout vm.relogio, 1000
      return

    vm.openFullScreen = (element)->
      isInFullScreen = !!(element.fullscreenElement || element.mozFullScreenElement ||
        element.webkitFullscreenElement || element.msFullscreenElement)
      return console.log 'Já está em fullScreen' if isInFullScreen

      element.requestFullscreen?()
      element.msRequestFullscreen?()
      element.mozRequestFullScreen?()
      element.webkitRequestFullScreen?()
      element.webkitRequestFullscreen?()

    vm
])

