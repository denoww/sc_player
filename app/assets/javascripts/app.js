// Generated by CoffeeScript 2.4.1
(function() {
  var app;

  app = angular.module('publicidade_app', ['ngSanitize']);

  app.controller('MainCtrl', [
    '$http',
    '$timeout',
    function($http,
    $timeout) {
      var vm;
      vm = this;
      vm.init = function() {
        return vm.grade.get(function() {
          return vm.feeds.get();
        });
      };
      vm.timeline = {
        tipos: ['conteudos',
    'musicas',
    'mensagens'],
        current: {},
        promessa: {},
        nextIndex: {},
        transicao: {},
        init: function() {
          var i,
    len,
    ref,
    results,
    tipo;
          if (vm.grade.loading || vm.feeds.loading) {
            return;
          }
          ref = this.tipos;
          results = [];
          for (i = 0, len = ref.length; i < len; i++) {
            tipo = ref[i];
            this.nextIndex[tipo] = 0;
            results.push(this.executar(tipo));
          }
          return results;
        },
        executar: function(tipo) {
          var currentItem,
    feed,
    feeds,
    i,
    index,
    item,
    len,
    lista,
    ref,
    ref1,
    ref2,
    segundos;
          lista = vm.grade.items[tipo] || [];
          this.transicao[tipo] = false;
          if (!lista.length) {
            return;
          }
          if ((ref = this.promessa) != null ? ref[tipo] : void 0) {
            $timeout.cancel(this.promessa[tipo]);
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
          this.next[tipo] = lista[this.nextIndex[tipo]];
          if (currentItem.tipo_midia === 'feed') {
            feeds = (ref1 = vm.feeds.items[currentItem.fonte]) != null ? ref1[currentItem.categoria] : void 0;
            if (feeds) {
              ref2 = feeds.lista;
              for (i = 0, len = ref2.length; i < len; i++) {
                item = ref2[i];
                if (item.exibido == null) {
                  item.exibido = 0;
                }
              }
              feed = feeds.lista.sortByField('exibido')[0];
              feed.exibido || (feed.exibido = 0);
              feed.exibido++;
              currentItem.nome = feed.nome;
              currentItem.data = feed.data;
              currentItem.titulo = feed.titulo;
              currentItem.titulo_feed = feed.titulo_feed;
            }
          }
          this.current[tipo] = currentItem;
          segundos = (this.current[tipo].segundos * 1000) || 5000;
          $timeout((function() {
            return vm.timeline.transicao[tipo] = true;
          }),
    segundos - 250);
          this.promessa[tipo] = $timeout((function() {
            return vm.timeline.next(tipo);
          }),
    segundos);
        },
        next: function(tipo) {
          this.current[tipo] = {};
          return $timeout(function() {
            return vm.timeline.executar(tipo);
          });
        }
      };
      vm.grade = {
        items: {},
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
            this.items = resp.data;
            vm.timeline.init();
            this.tentativas = 0;
            return typeof onSuccess === "function" ? onSuccess() : void 0;
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
        }
      };
      vm.feeds = {
        items: {},
        tentar: 10,
        tentativas: 0,
        get: function() {
          var error,
    success;
          if (this.loading) {
            return;
          }
          this.loading = true;
          success = (resp) => {
            this.loading = false;
            this.items = resp.data;
            vm.timeline.init();
            return this.tentativas = 0;
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
            return $timeout((function() {
              return vm.feeds.get();
            }),
    this.tentarNovamenteEm);
          };
          $http({
            method: 'GET',
            url: '/feeds'
          }).then(success,
    error);
        }
      };
      return vm;
    }
  ]);

}).call(this);
