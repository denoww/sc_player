app = angular.module('AnunciosVideos', [])
app.controller('PrincipalCtrl', [
  '$scope',
  '$http'
  ($s, $http) ->
    $s.mensagems =
      index: 0
      message:
        tempo: 1000
        titulo: 'aa'
        mensagem: ''
      getMessage: ->
        $http
          method: 'GET'
          url: '/messages'
          params: index: $s.mensagems.index
        .then (resp) ->
          $s.mensagems.index = resp.data.index
          $s.mensagems.message = resp.data.message
          $s.interval.clear()
          $s.interval.start resp.data.message.tempo
        , (error) ->
          console.log 'Error :$'

    $s.interval =
      scope: {}
      start: (time) ->
        # $s.interval.scope = setTimeout(function(){ $s.mensagems.getMessage(); }, time);
        return
      clear: ->
        clearTimeout $s.interval.scope
        return

    $s.interval.start $s.mensagems.message.tempo

    $s.anuncioVideo =
      index: 0
      getPlaylist: (video) ->
        $http
          method: 'GET'
          url: '/playlist'
        .then (resp) ->
          $s.anuncioVideo.index++
          if $s.anuncioVideo.index > resp.data.playlist_length - 1
            $s.anuncioVideo.index = 0
          video.src = '/video?id=' + $s.anuncioVideo.index
          return
        , (error) ->
          console.log 'Error :$'
          return
        return
    return
])
