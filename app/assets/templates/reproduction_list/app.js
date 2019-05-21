
var app = angular.module("AnunciosVideos",[]);

app.controller('PrincipalCtrl', [ '$scope', '$http', function($s, $http){
  $s.mensagems = {
    index: 0,
    message: {
      tempo: 1000,
      titulo: '',
      mensagem: '',
    },
    getMessage: function(){
      $http({
        method: 'GET',
        url: '/messages',
        params: {index: $s.mensagems.index}
      }).then(function successCallback(resp) {
        $s.mensagems.index = resp.data.index;
        $s.mensagems.message = resp.data.message

        $s.interval.clear();
        $s.interval.start(resp.data.message.tempo);
      }, function errorCallback(error) {
        console.log('Error :$');
      });
    }
  }

  $s.interval = {
    scope: {},
    start: function (time){
      // $s.interval.scope = setTimeout(function(){ $s.mensagems.getMessage(); }, time);
    },
    clear: function(){
      clearTimeout($s.interval.scope);
    }
  };

  $s.interval.start($s.mensagems.message.tempo);

  $s.anuncioVideo = {
    index:0,
    getPlaylist: function(video){
      $http({
        method: 'GET',
        url: '/playlist',
      }).then(function successCallback(resp) {
        $s.anuncioVideo.index++;
        if($s.anuncioVideo.index >resp.data.playlist_length-1) {
          $s.anuncioVideo.index = 0;
        };
        video.src = "http://localhost:3001/video?id="+$s.anuncioVideo.index;
      }, function errorCallback(error) {
        console.log('Error :$');
      });
    }
  }
}]);
