// Generated by CoffeeScript 2.4.1
(function() {
  var data, feedsObj, grade, relogio, timelineConteudos, timelineMensagens, vm;

  data = {
    body: void 0,
    loaded: false,
    loading: true,
    currentIndex: 0,
    playlist: [],
    grade: {
      data: {
        cor: 'black',
        layout: 'layout-2',
        weather: {}
      }
    },
    feeds: {
      data: {}
    },
    timeline: {
      conteudo: {},
      mensagem: {},
      transicao: {
        conteudos: false,
        mensagens: false
      }
    }
  };

  grade = {
    data: {},
    tentar: 10,
    tentativas: 0,
    get: function(onSuccess, onError) {
      var error, success;
      if (this.loading) {
        return;
      }
      this.loading = true;
      success = (resp) => {
        this.loading = false;
        this.tentativas = 0;
        this.data = resp.data;
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        this.mountWeatherData();
        this.handle(this.data);
        timelineConteudos.init();
        return timelineMensagens.init();
      };
      error = (resp) => {
        this.loading = false;
        timelineConteudos.init();
        timelineMensagens.init();
        console.error('Grade:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Grade: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Grade: Tentando em ${this.tentarNovamenteEm} segundos`);
        setTimeout((function() {
          return grade.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/grade').then(success, error);
    },
    mountWeatherData: function() {
      var dataHoje, dia, mes;
      if (!this.data.weather) {
        return;
      }
      dataHoje = new Date;
      dia = `${dataHoje.getDate()}`.rjust(2, '0');
      mes = `${dataHoje.getMonth() + 1}`.rjust(2, '0');
      dataHoje = `${dia}/${mes}`;
      dia = this.data.weather.proximos_dias[0];
      if (dia.data === dataHoje) {
        dia = this.data.weather.proximos_dias.shift();
        this.data.weather.max = dia.max;
        this.data.weather.min = dia.min;
      }
      this.data.weather.proximos_dias = this.data.weather.proximos_dias.slice(0, 4);
    },
    handle: function(data) {
      var dados;
      dados = this.data;
      dados.conteudos = ((dados != null ? dados.conteudos : void 0) || []).select(function(e) {
        return e.ativado;
      });
      dados.mensagens = ((dados != null ? dados.mensagens : void 0) || []).select(function(e) {
        return e.ativado;
      });
      dados.musicas = ((dados != null ? dados.musicas : void 0) || []).select(function(e) {
        return e.ativado;
      });
      vm.grade.data = dados;
    }
  };

  feedsObj = {
    data: {},
    tentar: 10,
    tentativas: 0,
    nextIndex: {},
    get: function(onSuccess, onError) {
      var error, success;
      if (this.loading) {
        return;
      }
      this.loading = true;
      success = (resp) => {
        this.loading = false;
        this.tentativas = 0;
        this.data = resp.data;
        this.verificarNoticias();
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        vm.feeds.data = this.data;
        timelineConteudos.init();
        return timelineMensagens.init();
      };
      error = (resp) => {
        this.loading = false;
        timelineConteudos.init();
        timelineMensagens.init();
        console.error('Feeds:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Feeds: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Feeds: Tentando em ${this.tentarNovamenteEm} segundos`);
        setTimeout((function() {
          return feedsObj.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/feeds').then(success, error);
    },
    verificarNoticias: function() {
      var categoria, categorias, cont, conteudos, fonte, i, len, ref, valores;
      ref = this.data;
      for (fonte in ref) {
        categorias = ref[fonte];
        for (categoria in categorias) {
          valores = categorias[categoria];
          if ((valores || []).empty()) {
            if (!grade.data.conteudos) {
              return;
            }
            conteudos = grade.data.conteudos.select(function(e) {
              return e.fonte === fonte && e.categoria === categoria;
            });
            for (i = 0, len = conteudos.length; i < len; i++) {
              cont = conteudos[i];
              cont.ativado = false;
            }
          }
        }
      }
    }
  };

  timelineConteudos = {
    promessa: null,
    nextIndex: 0,
    playlistIndex: {},
    init: function() {
      if (!vm.loaded) {
        return;
      }
      if (this.promessa == null) {
        return this.executar();
      }
    },
    executar: function() {
      var itemAtual, segundos;
      if (this.promessa) {
        clearTimeout(this.promessa);
      }
      itemAtual = this.getNextItem();
      if (!itemAtual) {
        return;
      }
      vm.currentIndex = vm.playlist.getIndexByField('id', itemAtual.id);
      if (vm.currentIndex == null) {
        vm.playlist.push(itemAtual);
        vm.currentIndex = vm.playlist.length - 1;
      }
      this.stopUltimoVideo();
      segundos = (itemAtual.segundos * 1000) || 5000;
      this.promessa = setTimeout(function() {
        itemAtual.active = false;
        return timelineConteudos.executar();
      }, segundos);
      if (itemAtual.is_video) {
        this.playVideo(itemAtual);
      }
    },
    playVideo: function(itemAtual) {
      this.ultimoVideo = `video-player-${itemAtual.id}`;
      setTimeout(() => {
        var video;
        video = document.getElementById(this.ultimoVideo);
        if (video) {
          video.currentTime = 0;
          return video.play();
        }
      });
      setTimeout(() => {
        var video;
        video = document.getElementById(this.ultimoVideo);
        if (video != null ? video.paused : void 0) {
          return video.play();
        }
      }, 1000);
    },
    stopUltimoVideo: function() {
      var video, videoId;
      videoId = this.ultimoVideo;
      if (!videoId) {
        return;
      }
      video = document.getElementById(videoId);
      if (video) {
        video.pause();
      }
      this.ultimoVideo = null;
    },
    getNextItem: function() {
      var currentItem, index, lista, total;
      lista = vm.grade.data.conteudos;
      total = lista.length;
      if (!total) {
        return;
      }
      index = this.nextIndex;
      if (index >= total) {
        index = 0;
      }
      this.nextIndex++;
      if (this.nextIndex >= total) {
        this.nextIndex = 0;
      }
      currentItem = lista[index];
      switch (currentItem.tipo_midia) {
        case 'feed':
          return this.getItemFeed(currentItem);
        case 'playlist':
          return this.getItemPlaylist(currentItem);
        default:
          return currentItem;
      }
    },
    getItemFeed: function(currentItem) {
      var base, categ, feed, feedIndex, feedItems, fonte, ref;
      feedItems = (ref = vm.feeds.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0;
      if ((feedItems || []).empty()) {
        return currentItem;
      }
      fonte = currentItem.fonte;
      categ = currentItem.categoria;
      (base = feedsObj.nextIndex)[fonte] || (base[fonte] = {});
      if (feedsObj.nextIndex[fonte][categ] == null) {
        feedsObj.nextIndex[fonte][categ] = 0;
      } else {
        feedsObj.nextIndex[fonte][categ]++;
      }
      if (feedsObj.nextIndex[fonte][categ] >= feedItems.length) {
        feedsObj.nextIndex[fonte][categ] = 0;
      }
      feedIndex = feedsObj.nextIndex[fonte][categ];
      feed = feedItems[feedIndex] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.id = `${currentItem.id}${feed.nome_arquivo}`;
      currentItem.data = feed.data;
      currentItem.titulo = feed.titulo;
      currentItem.titulo_feed = feed.titulo_feed;
      currentItem.nome_arquivo = feed.nome_arquivo;
      return currentItem;
    },
    getItemPlaylist: function(playlist) {
      var currentItem;
      if (this.playlistIndex[playlist.id] == null) {
        this.playlistIndex[playlist.id] = 0;
      } else {
        this.playlistIndex[playlist.id]++;
      }
      if (this.playlistIndex[playlist.id] >= playlist.conteudos.length) {
        this.playlistIndex[playlist.id] = 0;
      }
      currentItem = playlist.conteudos[this.playlistIndex[playlist.id]];
      if (currentItem.tipo_midia !== 'feed') {
        return currentItem;
      }
      return this.getItemFeed(currentItem);
    }
  };

  timelineMensagens = {
    current: {},
    promessa: null,
    nextIndex: 0,
    init: function() {
      if (!vm.loaded) {
        return;
      }
      if (this.promessa == null) {
        return this.executar();
      }
    },
    executar: function() {
      var segundos;
      if (this.promessa) {
        clearTimeout(this.promessa);
      }
      vm.timeline.mensagem = this.getNextItem();
      if (!vm.timeline.mensagem) {
        return;
      }
      segundos = (vm.timeline.mensagem.segundos * 1000) || 5000;
      this.promessa = setTimeout((function() {
        return timelineMensagens.executar();
      }), segundos);
    },
    getNextItem: function() {
      var index, lista, total;
      lista = vm.grade.data.mensagens;
      total = lista.length;
      if (!total) {
        return;
      }
      index = this.nextIndex;
      if (index >= total) {
        index = 0;
      }
      this.nextIndex++;
      if (this.nextIndex >= total) {
        this.nextIndex = 0;
      }
      return lista[index];
    }
  };

  relogio = {
    exec: function() {
      var hour, min, now, sec;
      now = new Date;
      hour = now.getHours();
      min = now.getMinutes();
      sec = now.getSeconds();
      if (hour < 10) {
        hour = `0${hour}`;
      }
      if (min < 10) {
        min = `0${min}`;
      }
      if (sec < 10) {
        sec = `0${sec}`;
      }
      this.elemHora || (this.elemHora = document.getElementById('hora'));
      if (this.elemHora) {
        this.elemHora.innerHTML = hour + ':' + min + ':' + sec;
      }
      setTimeout(relogio.exec, 1000);
    }
  };

  vm = new Vue({
    el: '#main-player',
    data: data,
    methods: {
      playVideo: timelineConteudos.playVideo,
      mouse: function() {
        if (this.mouseTimeout) {
          clearTimeout(this.mouseTimeout);
        }
        this.body || (this.body = document.getElementById('body-player'));
        this.body.style.cursor = 'default';
        return this.mouseTimeout = setTimeout(() => {
          return this.body.style.cursor = 'none';
        }, 1000);
      }
    },
    computed: {
      now: function() {
        return Date.now();
      }
    },
    mounted: function() {
      this.loading = true;
      this.mouse();
      relogio.exec();
      setTimeout(function() {
        return grade.get(function() {
          return feedsObj.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000);
      return setInterval(function() {
        return grade.get(function() {
          return feedsObj.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000 * 60); // a cada minuto
    }
  });

  Vue.filter('formatDate', function(value) {
    if (value) {
      return moment(value).format('DD MMM');
    }
  });

  Vue.filter('formatWeek', function(value) {
    if (value) {
      return moment(value).format('dddd');
    }
  });

  Vue.filter('currency', function(value) {
    return (value || 0).toLocaleString('pt-Br', {
      minimumFractionDigits: 2,
      maximumFractionDigits: 2
    });
  });

}).call(this);
