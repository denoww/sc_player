app = angular.module('publicidade_app', [])
app.controller('MainCtrl', [
  '$http'
  ($http)->
    vm = @

    vm.init = ->
      vm.cor    = 'black'
      vm.layout = 'layout-2'

      video = document.getElementById('video-player')
      video.onended = (event)-> vm.anuncioVideo.getPlaylist(video)

    vm.mensagems =
      index: 0
      message:
        tempo: 1000
        titulo: 'Globally envisioneer tactical web-readiness'
        mensagem: 'Energistically integrate error-free opportunities and alternative applications. Authoritatively repurpose client-centered strategic theme areas via flexible metrics. Globally envisioneer tactical web-readiness via multidisciplinary functionalities. Compellingly plagiarize.'
      getMessage: ->
        $http
          method: 'GET'
          url: '/messages'
          params: index: vm.mensagems.index
        .then (resp)->
          vm.mensagems.index = resp.data.index
          vm.mensagems.message = resp.data.message
          vm.interval.clear()
          vm.interval.start resp.data.message.tempo
        , (error)->
          console.log 'Error', error

    vm.interval =
      scope: {}
      start: (time)->
        # vm.interval.scope = setTimeout(function(){ vm.mensagems.getMessage(); }, time);
        return
      clear: ->
        clearTimeout vm.interval.scope
        return

    vm.interval.start vm.mensagems.message.tempo

    vm.anuncioVideo =
      index: 0
      getPlaylist: (video)->
        $http
          method: 'GET'
          url: '/playlist'
        .then (resp)->
          vm.anuncioVideo.index++
          if vm.anuncioVideo.index > resp.data.playlist_length - 1
            vm.anuncioVideo.index = 0
          video.src = '/video?id=' + vm.anuncioVideo.index
          return
        , (error)->
          console.error 'Erro:', error
          return
        return

    vm
])

