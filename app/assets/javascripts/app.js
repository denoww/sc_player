// Generated by CoffeeScript 2.4.1
(function() {
  var data, feeds, grade, relogio, timeline, vm;

  data = {
    body: void 0,
    loaded: false,
    loading: true,
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
      conteudos: [],
      mensagens: [],
      musicas: [],
      transicao: {
        conteudos: false,
        mensagens: false,
        musicas: false
      },
      current: {
        conteudos: {},
        mensagens: {},
        musicas: {}
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
        vm.grade.data = this.data;
        return timeline.init();
      };
      error = (resp) => {
        this.loading = false;
        timeline.init();
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
    }
  };

  feeds = {
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
        return timeline.init();
      };
      error = (resp) => {
        this.loading = false;
        timeline.init();
        console.error('Feeds:', resp);
        this.tentativas++;
        if (this.tentativas > this.tentar) {
          console.error('Feeds: Não foi possível comunicar com o servidor!');
          return;
        }
        this.tentarNovamenteEm = 1000 * this.tentativas;
        console.warn(`Feeds: Tentando em ${this.tentarNovamenteEm} segundos`);
        setTimeout((function() {
          return feeds.get();
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

  timeline = {
    tipos: ['conteudos', 'musicas', 'mensagens'],
    current: {},
    promessa: {},
    nextIndex: {},
    transicao: {},
    playlistIndex: {},
    init: function() {
      var base, i, len, ref, ref1, results, tipo;
      if (!vm.loaded) {
        return;
      }
      ref = this.tipos;
      results = [];
      for (i = 0, len = ref.length; i < len; i++) {
        tipo = ref[i];
        (base = this.nextIndex)[tipo] || (base[tipo] = 0);
        if (((ref1 = this.promessa) != null ? ref1[tipo] : void 0) == null) {
          results.push(this.executar(tipo));
        } else {
          results.push(void 0);
        }
      }
      return results;
    },
    executar: function(tipo) {
      var ref, segundos;
      this.transicao[tipo] = false;
      if ((ref = this.promessa) != null ? ref[tipo] : void 0) {
        clearTimeout(this.promessa[tipo]);
      }
      vm.timeline.current[tipo] = this.getNextItem(tipo);
      if (!vm.timeline.current[tipo]) {
        return;
      }
      segundos = (vm.timeline.current[tipo].segundos * 1000) || 5000;
      vm.timeline.transicao[tipo] = true;
      setTimeout((function() {
        return vm.timeline.transicao[tipo] = false;
      }), 250);
      setTimeout((function() {
        return vm.timeline.transicao[tipo] = true;
      }), segundos - 250);
      this.promessa[tipo] = setTimeout((function() {
        return timeline.executar(tipo);
      }), segundos);
      if (vm.timeline.current[tipo].is_video) {
        this.playVideo();
      }
    },
    playVideo: function(tipo) {
      setTimeout(function() {
        var video;
        video = document.getElementById('video-player');
        if (video != null ? video.paused : void 0) {
          return video.play();
        }
      });
    },
    getNextItem: function(tipo) {
      var currentItem, index, lista;
      lista = (vm.grade.data[tipo] || []).select(function(e) {
        return e.ativado;
      });
      if (!lista.length) {
        return;
      }
      index = this.nextIndex[tipo];
      if (index >= lista.length) {
        index = 0;
      }
      this.nextIndex[tipo]++;
      if (this.nextIndex[tipo] >= lista.length) {
        this.nextIndex[tipo] = 0;
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
      (base = feeds.nextIndex)[fonte] || (base[fonte] = {});
      if (feeds.nextIndex[fonte][categ] == null) {
        feeds.nextIndex[fonte][categ] = 0;
      } else {
        feeds.nextIndex[fonte][categ]++;
      }
      if (feeds.nextIndex[fonte][categ] >= feedItems.length) {
        feeds.nextIndex[fonte][categ] = 0;
      }
      feedIndex = feeds.nextIndex[fonte][categ];
      feed = feedItems[feedIndex] || feedItems[0];
      if (!feed) {
        return;
      }
      currentItem.nome = feed.nome;
      currentItem.data = feed.data;
      currentItem.titulo = feed.titulo;
      currentItem.titulo_feed = feed.titulo_feed;
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

  relogio = {
    exec: function() {
      var hour, min, now, sec;
      now = new Date;
      hour = now.getHours();
      min = now.getMinutes();
      sec = now.getSeconds();
      hour = `${hour}`.rjust(2, '0');
      min = `${min}`.rjust(2, '0');
      sec = `${sec}`.rjust(2, '0');
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
    created: function() {
      this.loading = true;
      this.mouse();
      relogio.exec();
      grade.get(function() {
        return feeds.get(function() {
          vm.loading = false;
          return vm.loaded = true;
        });
      });
      return setInterval(function() {
        return grade.get(function() {
          return feeds.get(function() {
            vm.loading = false;
            return vm.loaded = true;
          });
        });
      }, 1000 * 60); // a cada minuto
    },
    mounted: function() {}
  });

  Vue.filter('formatDate', function(value) {
    if (value) {
      return moment(value).format('LL');
    }
  });

  Vue.filter('formatWeek', function(value) {
    if (value) {
      return moment(value).format('dddd');
    }
  });

  Vue.filter('currency', function(value) {
    return (value || 0).toLocaleString('pt-Br', {
      maximumFractionDigits: 2
    });
  });

}).call(this);
