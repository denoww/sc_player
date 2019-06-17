// Generated by CoffeeScript 2.4.1
(function() {
  var app;

  app = angular.module('publicidade_app', ['ngSanitize', 'ngLocale']);

  app.config([
    '$qProvider',
    function($qProvider) {
      return $qProvider.errorOnUnhandledRejections(false);
    }
  ]);

  app.controller('MainCtrl', [
    '$http',
    '$timeout',
    function($http,
    $timeout) {
      var vm;
      vm = this;
      vm.loading = true;
      vm.init = function() {
        vm.loading = true;
        vm.grade.get(function() {
          return vm.feeds.get(function() {
            vm.loading = false;
            vm.loaded = true;
            return vm.relogio();
          });
        });
        return setInterval(function() {
          return vm.grade.get(function() {
            return vm.feeds.get();
          });
        },
    1000 * 60); // a cada minuto
      };
      vm.timeline = {
        tipos: ['conteudos',
    'musicas',
    'mensagens'],
        current: {},
        promessa: {},
        nextIndex: {},
        transicao: {},
        playlistIndex: {},
        init: function() {
          var base,
    i,
    len,
    ref,
    ref1,
    ref2,
    ref3,
    results,
    tipo;
          if (!vm.loaded) {
            return;
          }
          ref = this.tipos;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            tipo = ref[i];
            (base = this.nextIndex)[tipo] || (base[tipo] = 0);
            if (((ref1 = this.promessa) != null ? (ref2 = ref1[tipo]) != null ? (ref3 = ref2.$$state) != null ? ref3.status : void 0 : void 0 : void 0) !== 0) {
              // console.log '------------------', @promessa?[tipo]?.$$state?.status, @promessa?[tipo]?.$$state?.status != 0 if tipo == 'conteudos'
              results.push(this.executar(tipo));
            } else {
              results.push(void 0);
            }
          }
          return results;
        },
        executar: function(tipo) {
          var ref,
    segundos;
          this.transicao[tipo] = false;
          if ((ref = this.promessa) != null ? ref[tipo] : void 0) {
            $timeout.cancel(this.promessa[tipo]);
          }
          this.current[tipo] = this.getNextItem(tipo);
          if (!this.current[tipo]) {
            return;
          }
          segundos = (this.current[tipo].segundos * 1000) || 5000;
          vm.timeline.transicao[tipo] = true;
          $timeout((function() {
            return vm.timeline.transicao[tipo] = false;
          }),
    250);
          $timeout((function() {
            return vm.timeline.transicao[tipo] = true;
          }),
    segundos - 250);
          this.promessa[tipo] = $timeout((function() {
            return vm.timeline.next(tipo);
          }),
    segundos);
        },
        getNextItem: function(tipo) {
          var currentItem,
    index,
    lista;
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
          // if tipo == 'conteudos'
          // console.log '---------------------------------------------------------'
          // console.log 'getNextItem', tipo, @nextIndex, lista.length
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
          var base,
    categ,
    feed,
    feedIndex,
    feedItems,
    fonte,
    ref;
          feedItems = (ref = vm.feeds.data[currentItem.fonte]) != null ? ref[currentItem.categoria] : void 0;
          if ((feedItems || []).empty()) {
            return currentItem;
          }
          fonte = currentItem.fonte;
          categ = currentItem.categoria;
          (base = vm.feeds.nextIndex)[fonte] || (base[fonte] = {});
          if (vm.feeds.nextIndex[fonte][categ] == null) {
            vm.feeds.nextIndex[fonte][categ] = 0;
          } else {
            vm.feeds.nextIndex[fonte][categ]++;
          }
          if (vm.feeds.nextIndex[fonte][categ] >= feedItems.length) {
            vm.feeds.nextIndex[fonte][categ] = 0;
          }
          feedIndex = vm.feeds.nextIndex[fonte][categ];
          feed = feedItems[feedIndex] || feedItems[0];
          if (!feed) {
            return;
          }
          currentItem.nome = feed.nome;
          currentItem.data = feed.data;
          currentItem.titulo = feed.titulo;
          currentItem.titulo_feed = feed.titulo_feed;
          console.log('FEED ---->',
    fonte,
    categ,
    `${feedIndex}/${feedItems.length - 1}`,
    currentItem);
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
          console.log('PLAYLIST ---->',
    `${this.playlistIndex[playlist.id]}/${playlist.conteudos.length - 1}`,
    currentItem);
          if (currentItem.tipo_midia !== 'feed') {
            return currentItem;
          }
          return this.getItemFeed(currentItem);
        },
        next: function(tipo) {
          this.current[tipo] = {};
          return $timeout(function() {
            return vm.timeline.executar(tipo);
          });
        }
      };
      vm.grade = {
        data: {},
        tentar: 10,
        tentativas: 0,
        get: function(onSuccess,
    onError) {
          var error,
    success;
          if (this.loading) {
            return;
          }
          this.loading = true;
          success = (resp) => {
            this.loading = false;
            this.tentativas = 0;
            vm.offline = resp.data.offline;
            this.data = resp.data;
            if (typeof onSuccess === "function") {
              onSuccess();
            }
            this.mountWeatherData();
            return vm.timeline.init();
          };
          error = (resp) => {
            this.loading = false;
            vm.timeline.init();
            console.error('Grade:',
    resp);
            this.tentativas++;
            if (this.tentativas > this.tentar) {
              console.error('Grade: Não foi possível comunicar com o servidor!');
              return;
            }
            this.tentarNovamenteEm = 1000 * this.tentativas;
            console.warn(`Grade: Tentando em ${this.tentarNovamenteEm} segundos`);
            $timeout((function() {
              return vm.grade.get();
            }),
    this.tentarNovamenteEm);
            return typeof onError === "function" ? onError() : void 0;
          };
          $http({
            method: 'GET',
            url: '/grade'
          }).then(success,
    error);
        },
        mountWeatherData: function() {
          var dataHoje,
    dia,
    mes;
          if (!this.data.weather) {
            return;
          }
          dataHoje = new Date;
          dia = `${dataHoje.getDate()}`.rjust(2,
    '0');
          mes = `${dataHoje.getMonth() + 1}`.rjust(2,
    '0');
          dataHoje = `${dia}/${mes}`;
          dia = this.data.weather.proximos_dias[0];
          if (dia.data === dataHoje) {
            dia = this.data.weather.proximos_dias.shift();
            this.data.weather.max = dia.max;
            this.data.weather.min = dia.min;
          }
        }
      };
      vm.feeds = {
        data: {},
        tentar: 10,
        tentativas: 0,
        nextIndex: {},
        get: function(onSuccess,
    onError) {
          var error,
    success;
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
            return vm.timeline.init();
          };
          error = (resp) => {
            this.loading = false;
            vm.timeline.init();
            console.error('Feeds:',
    resp);
            this.tentativas++;
            if (this.tentativas > this.tentar) {
              console.error('Feeds: Não foi possível comunicar com o servidor!');
              return;
            }
            this.tentarNovamenteEm = 1000 * this.tentativas;
            console.warn(`Feeds: Tentando em ${this.tentarNovamenteEm} segundos`);
            $timeout((function() {
              return vm.feeds.get();
            }),
    this.tentarNovamenteEm);
            return typeof onError === "function" ? onError() : void 0;
          };
          $http({
            method: 'GET',
            url: '/feeds'
          }).then(success,
    error);
        },
        verificarNoticias: function() {
          var categoria,
    categorias,
    cont,
    conteudos,
    fonte,
    i,
    len,
    ref,
    valores;
          ref = this.data;
          for (fonte in ref) {
            categorias = ref[fonte];
            for (categoria in categorias) {
              valores = categorias[categoria];
              // console.log 'fonte', fonte, 'categoria', categoria, (valores || []).empty()
              if ((valores || []).empty()) {
                if (!vm.grade.data.conteudos) {
                  return;
                }
                conteudos = vm.grade.data.conteudos.select(function(e) {
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
      vm.mouse = {
        onMove: function() {
          if (this.timeout) {
            $timeout.cancel(this.timeout);
          }
          document.body.style.cursor = 'default';
          return this.timeout = $timeout(() => {
            return document.body.style.cursor = 'none';
          },
    1000);
        }
      };
      vm.relogio = function() {
        var elem,
    hour,
    min,
    sec;
        vm.now = new Date;
        hour = vm.now.getHours();
        min = vm.now.getMinutes();
        sec = vm.now.getSeconds();
        hour = `${hour}`.rjust(2,
    '0');
        min = `${min}`.rjust(2,
    '0');
        sec = `${sec}`.rjust(2,
    '0');
        elem = document.getElementById('hora');
        if (elem) {
          elem.innerHTML = hour + ':' + min + ':' + sec;
        }
        setTimeout(vm.relogio,
    1000);
      };
      return vm;
    }
  ]);

}).call(this);
