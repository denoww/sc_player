// Generated by CoffeeScript 2.4.1
(function() {
  var data, feedsObj, gradeObj, onLoaded, relogio, timelineConteudoMensagem, timelineConteudoSuperior, vm;

  data = {
    body: void 0,
    loaded: false,
    loading: true,
    indexConteudoSuperior: 0,
    indexConteudoMensagem: 0,
    listaConteudoSuperior: [],
    listaConteudoMensagem: [],
    grade: {
      data: {
        cor: 'black',
        layout: 'layout-2',
        weather: {}
      }
    }
  };

  onLoaded = function() {
    timelineConteudoSuperior.init();
    return timelineConteudoMensagem.init();
  };

  gradeObj = {
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
        this.handle(resp.data);
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        this.mountWeatherData();
        return onLoaded();
      };
      error = (resp) => {
        this.loading = false;
        onLoaded();
        console.error('Grade:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Grade: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Grade: Tentando em ${this.tentarNovamenteEm / 1000} segundos`);
        setTimeout((function() {
          return gradeObj.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/grade').then(success, error);
    },
    handle: function(data) {
      this.data = data;
      vm.grade.data = data;
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
    }
  };

  feedsObj = {
    data: {},
    tentar: 10,
    tentativas: 0,
    posicoes: ['conteudo_superior', 'conteudo_mensagem'],
    get: function(onSuccess, onError) {
      var error, success;
      if (this.loading) {
        return;
      }
      this.loading = true;
      success = (resp) => {
        this.loading = false;
        this.tentativas = 0;
        this.handle(resp.data);
        this.verificarNoticias();
        if (typeof onSuccess === "function") {
          onSuccess();
        }
        return onLoaded();
      };
      error = (resp) => {
        this.loading = false;
        onLoaded();
        console.error('Feeds:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Feeds: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Feeds: Tentando em ${this.tentarNovamenteEm / 1000} segundos`);
        setTimeout((function() {
          return feedsObj.get();
        }), this.tentarNovamenteEm);
        return typeof onError === "function" ? onError() : void 0;
      };
      Vue.http.get('/feeds').then(success, error);
    },
    handle: function(data) {
      var base, base1, feed, feeds, i, j, len, len1, name, name1, posicao, ref;
      this.data = data;
      ref = this.posicoes;
      // pre-montar a estrutura dos feeds com base na grade para ser usado em verificarNoticias()
      for (i = 0, len = ref.length; i < len; i++) {
        posicao = ref[i];
        feeds = vm.grade.data[posicao].select(function(e) {
          return e.tipo_midia === 'feed';
        });
        for (j = 0, len1 = feeds.length; j < len1; j++) {
          feed = feeds[j];
          (base = this.data)[name = feed.fonte] || (base[name] = {});
          (base1 = this.data[feed.fonte])[name1 = feed.categoria] || (base1[name1] = []);
        }
      }
    },
    verificarNoticias: function() {
      var categoria, categorias, fonte, i, item, items, j, len, len1, noticias, posicao, ref, ref1;
      ref = this.data;
      // serve para remover feeds que nao tem noticias
      for (fonte in ref) {
        categorias = ref[fonte];
        for (categoria in categorias) {
          noticias = categorias[categoria];
          if ((noticias || []).empty()) {
            ref1 = this.posicoes;
            for (i = 0, len = ref1.length; i < len; i++) {
              posicao = ref1[i];
              if (!vm.grade.data[posicao]) {
                continue;
              }
              items = vm.grade.data[posicao].select(function(e) {
                return e.fonte === fonte && e.categoria === categoria;
              });
              for (j = 0, len1 = items.length; j < len1; j++) {
                item = items[j];
                vm.grade.data[posicao].removeById(item.id);
              }
            }
          }
        }
      }
    }
  };

  timelineConteudoSuperior = {
    promessa: null,
    nextIndex: 0,
    feedIndex: {},
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
      vm.indexConteudoSuperior = vm.listaConteudoSuperior.getIndexByField('id', itemAtual.id);
      if (vm.indexConteudoSuperior == null) {
        vm.listaConteudoSuperior.push(itemAtual);
        vm.indexConteudoSuperior = vm.listaConteudoSuperior.length - 1;
      }
      this.stopUltimoVideo();
      segundos = (itemAtual.segundos * 1000) || 5000;
      this.promessa = setTimeout(function() {
        return timelineConteudoSuperior.executar();
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
      lista = vm.grade.data.conteudo_superior;
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
      var base, categ, feed, feedItems, fonte, index, ref;
      feedItems = ((ref = feedsObj.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0) || [];
      if (feedItems.empty()) {
        return currentItem;
      }
      fonte = currentItem.fonte;
      categ = currentItem.categoria;
      (base = this.feedIndex)[fonte] || (base[fonte] = {});
      if (this.feedIndex[fonte][categ] == null) {
        this.feedIndex[fonte][categ] = 0;
      } else {
        this.feedIndex[fonte][categ]++;
      }
      if (this.feedIndex[fonte][categ] >= feedItems.length) {
        this.feedIndex[fonte][categ] = 0;
      }
      index = this.feedIndex[fonte][categ];
      feed = feedItems[index] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.id = `${currentItem.id}${feed.nome_arquivo}`;
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
      if (this.playlistIndex[playlist.id] >= playlist.conteudo_superior.length) {
        this.playlistIndex[playlist.id] = 0;
      }
      currentItem = playlist.conteudo_superior[this.playlistIndex[playlist.id]];
      if (currentItem.tipo_midia !== 'feed') {
        return currentItem;
      }
      return this.getItemFeed(currentItem);
    }
  };

  timelineConteudoMensagem = {
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
      vm.indexConteudoMensagem = vm.listaConteudoMensagem.getIndexByField('id', itemAtual.id);
      if (vm.indexConteudoMensagem == null) {
        vm.listaConteudoMensagem.push(itemAtual);
        vm.indexConteudoMensagem = vm.listaConteudoMensagem.length - 1;
      }
      segundos = (itemAtual.segundos * 1000) || 5000;
      this.promessa = setTimeout(function() {
        return timelineConteudoMensagem.executar();
      }, segundos);
    },
    getNextItem: function() {
      var currentItem, index, lista, total;
      lista = vm.grade.data.conteudo_mensagem;
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
        default:
          return currentItem;
      }
    },
    getItemFeed: function(currentItem) {
      var feed, feedItems, index, ref;
      feedItems = ((ref = feedsObj.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0) || [];
      if (feedItems.empty()) {
        return currentItem;
      }
      index = parseInt(Math.random() * 100) % feedItems.length;
      feed = feedItems[index] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.id = `${currentItem.id}${feed.titulo}`;
      currentItem.titulo = feed.titulo;
      currentItem.titulo_feed = feed.titulo_feed;
      return currentItem;
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
      playVideo: timelineConteudoSuperior.playVideo,
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
        return gradeObj.get(function() {
          return feedsObj.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000);
      return setInterval(function() {
        return gradeObj.get(function() {
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
