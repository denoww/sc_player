app = angular.module('publicidade_app', ['ngSanitize'])
app.controller('MainCtrl', [
  '$http', '$timeout'
  ($http, $timeout)->
    vm = @

    vm.init = ->
      vm.loading = true

      vm.grade.get ->
        vm.feeds.get ->
          vm.loading = false
          vm.loaded = true

    vm.timeline =
      tipos:     ['conteudos', 'musicas', 'mensagens']
      current:   {}
      promessa:  {}
      nextIndex: {}
      transicao: {}
      init: ->
        return if vm.grade.loading || vm.feeds.loading

        for tipo in @tipos
          @nextIndex[tipo] = 0
          @executar(tipo)
      executar: (tipo)->
        @transicao[tipo] = false
        $timeout.cancel(@promessa[tipo]) if @promessa?[tipo]

        @current[tipo] = @getNextItem(tipo)
        return unless @current[tipo]

        segundos = (@current[tipo].segundos * 1000) || 5000
        $timeout (-> vm.timeline.transicao[tipo] = true), segundos - 250
        @promessa[tipo] = $timeout (-> vm.timeline.next(tipo)), segundos
        return
      getNextItem: (tipo)->
        lista = vm.grade.data[tipo] || []
        return unless lista.length

        index = @nextIndex[tipo]
        index = 0 if index >= lista.length

        @nextIndex[tipo]++
        @nextIndex[tipo] = 0 if @nextIndex[tipo] >= lista.length

        currentItem = lista[index]
        return currentItem if currentItem.tipo_midia != 'feed'

        feeds = vm.feeds.data[currentItem.fonte]?[currentItem.categoria]
        if feeds
          item.exibido = 0 for item in feeds.lista when !item.exibido?
          feed = feeds.lista.sortByField('exibido')[0]
          feed.exibido ||= 0
          feed.exibido++

          currentItem.nome   = feed.nome
          currentItem.data   = feed.data
          currentItem.titulo = feed.titulo
          currentItem.titulo_feed = feed.titulo_feed

        currentItem
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
          @loading = false
          @data = resp.data
          vm.offline = resp.data.offline
          vm.timeline.init()
          @tentativas = 0
          onSuccess?()

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

    vm.feeds =
      data: {}
      tentar: 10
      tentativas: 0
      get: (onSuccess, onError)->
        return if @loading
        @loading = true

        success = (resp)=>
          @loading = false
          @data = resp.data
          vm.timeline.init()
          @tentativas = 0
          onSuccess?()

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

    vm.mouse =
      onMove: ->
        $timeout.cancel(@timeout) if @timeout
        document.body.style.cursor = 'default'

        @timeout = $timeout =>
          document.body.style.cursor = 'none'
        , 1000

    vm
])

