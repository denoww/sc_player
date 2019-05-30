app = angular.module('publicidade_app', ['ngSanitize'])
app.controller('MainCtrl', [
  '$http', '$timeout'
  ($http, $timeout)->
    vm = @
    vm.tentar = 10
    vm.tentativas = 0

    vm.init = ->
      vm.loading = true

      onSuccess = (data)->
        vm.loading = false
        console.log data
        vm.tentativas = 0
        vm.timeline.init()

      onError = ->
        vm.loading = false
        vm.tentativas++

        if vm.tentativas > vm.tentar
          console.log 'Não foi possível comunicar com o servidor!'
          return

        vm.tentarNovamenteEm = 1000 * vm.tentativas
        console.log "tentando em #{vm.tentarNovamenteEm} segundos"
        $timeout (-> vm.init()), vm.tentarNovamenteEm

      vm.getGrade onSuccess, onError

    vm.timeline =
      next:      {}
      tipos:     ['conteudos', 'musicas', 'mensagens']
      current:   {}
      nextIndex: {}
      transicao: {}
      init: ->
        for tipo in @tipos
          @nextIndex[tipo] = 0
          @executar(tipo)
      executar: (tipo)->
        lista = vm.grade[tipo] || []
        @transicao[tipo] = false
        return unless lista.length

        index = @nextIndex[tipo]
        index = 0 if index >= lista.length

        @nextIndex[tipo]++
        @nextIndex[tipo] = 0 if @nextIndex[tipo] >= lista.length

        @current[tipo] = lista[index]
        @next[tipo] = lista[@nextIndex[tipo]]
        console.log @current[tipo]
        console.log 'segundos', @current[tipo].segundos * 10000

        segundos = (@current[tipo].segundos * 1000) || 5000
        $timeout (-> vm.timeline.transicao[tipo] = true), segundos - 250
        $timeout (-> vm.timeline.executar(tipo)), segundos

    vm.getGrade = (callbackSuccess, callbackError)->
      $http
        method: 'GET'
        url: '/grade'
      .then (resp)->
        vm.grade = resp.data
        callbackSuccess?(resp.data)
      , (resp)->
        console.error 'Erro:', resp.data?.error
        callbackError?()
        return

    vm
])

