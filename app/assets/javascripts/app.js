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
        vm.weather.get();
        vm.finance.get();
        setInterval(function() {
          vm.grade.get(function() {
            return vm.feeds.get();
          });
          return vm.weather.get();
        },
    1000 * 60); // a cada minuto
        return setInterval(function() {
          return vm.finance.get();
        },
    1000 * 60 * 5); // a cada 5 minutos
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
          if (currentItem.tipo_midia !== 'feed') {
            // console.log 'currentItem', currentItem if tipo == 'conteudos'
            return currentItem;
          }
          return this.getItemFeed(currentItem);
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
          console.log('exibido ---->',
    fonte,
    categ,
    `${feedIndex}/${feedItems.length - 1}`,
    currentItem);
          return currentItem;
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
      vm.weather = {
        apiKey: '163e87549d7123a2f1ee5d6ba165e40f',
        url: 'http://api.openweathermap.org/data/2.5/weather?units=metric',
        get: function() {
          var error,
    success,
    url;
          if (this.loading) {
            return;
          }
          this.loading = true;
          vm.lat = -16.686902;
          vm.lon = -49.264788;
          success = (resp) => {
            this.loading = false;
            this.loaded = true;
            // console.log 'resp.data', resp.data
            return this.handle(resp.data);
          };
          // console.log 'weather', @data
          error = (resp) => {
            this.loading = false;
            return console.error('Weather:',
    resp);
          };
          url = `${this.url}&lat=${vm.lat}&lon=${vm.lon}&appid=${this.apiKey}`;
          return $http({
            method: 'GET',
            url: url
          }).then(success,
    error);
        },
        // $http.get(url, requestOptions).then success, error
        handle: function(dataObj) {
          var weather;
          if (!dataObj) {
            return;
          }
          this.data || (this.data = {});
          if (dataObj.main.temp) {
            this.data.temperatura = parseInt(dataObj.main.temp);
          }
          if (dataObj.main.humidity) {
            this.data.umidade = parseInt(dataObj.main.humidity);
          }
          if ((dataObj.weather || []).any()) {
            weather = dataObj.weather[0];
            this.data.icone = this.getIcon(weather.icon);
            this.data.descricao = this.getDescricao(weather.description);
          }
          if (dataObj.wind.speed) {
            // m/s * 3.6 = km/h
            this.data.vento = Math.ceil(dataObj.wind.speed * 3.6);
          }
        },
        // console.log 'weather ->', @data
        getIcon: function(icon) {
          var icone;
          icone = (function() {
            switch (true) {
              case /01/.test(icon):
                return 'clear_sky';
              case /02/.test(icon):
                return 'few_clouds';
              case /03/.test(icon):
                return 'scattered_clouds';
              case /04/.test(icon):
                return 'broken_clouds';
              case /09/.test(icon):
                return 'shower_rain';
              case /10/.test(icon):
                return 'rain';
              case /11/.test(icon):
                return 'thunderstorm';
              case /13/.test(icon):
                return 'snow';
              case /50/.test(icon):
                return 'mist';
              default:
                return 'few_clouds';
            }
          })();
          if (icon.match(/\d{2}n/)) {
            icone += '_n';
          }
          return icone;
        },
        getDescricao: function(desc) {
          switch (desc) {
            case 'thunderstorm with light rain':
              return 'Trovoada com chuva';
            case 'thunderstorm with rain':
              return 'Trovoada com chuva';
            case 'thunderstorm with heavy rain':
              return 'Trovoada com chuva';
            case 'light thunderstorm':
              return 'Trovoada e relâmpagos';
            case 'thunderstorm':
              return 'Trovoada';
            case 'heavy thunderstorm':
              return 'Trovoada pesada';
            case 'ragged thunderstorm':
              return 'Trovoada irregular';
            case 'thunderstorm with light drizzle':
              return 'Trovoada com leve garoa';
            case 'thunderstorm with drizzle':
              return 'Trovoada com chuvisco';
            case 'thunderstorm with heavy drizzle':
              return 'Trovoada com chuva';
            case 'light intensity drizzle':
              return 'Chuvisco leve';
            case 'drizzle':
              return 'Chuvisco';
            case 'heavy intensity drizzle':
              return 'Chuvisco forte';
            case 'light intensity drizzle rain':
              return 'Chuva leve';
            case 'drizzle rain':
              return 'Chuva';
            case 'heavy intensity drizzle rain':
              return 'Chuva forte';
            case 'shower rain and drizzle':
              return 'Chuva e chuvisco';
            case 'heavy shower rain and drizzle':
              return 'Chuva forte';
            case 'shower drizzle':
              return 'Chuvisco';
            case 'light rain':
              return 'Chuva leve';
            case 'moderate rain':
              return 'Chuva moderada';
            case 'heavy intensity rain':
              return 'Chuva intensa';
            case 'very heavy rain':
              return 'Chuva muito forte';
            case 'extreme rain':
              return 'Chuva extrema';
            case 'freezing rain':
              return 'Chuva';
            case 'light intensity shower rain':
              return 'Chuva leve';
            case 'shower rain':
              return 'Chuva de banho';
            case 'heavy intensity shower rain':
              return 'Chuva forte';
            case 'ragged shower rain':
              return 'Chuva irregular';
            case 'light snow':
              return 'Pouca neve';
            case 'Snow':
              return 'Neve';
            case 'Heavy snow':
              return 'Neve pesada';
            case 'Sleet':
              return 'Chuva com neve';
            case 'Light shower sleet':
              return 'Chuva de granizo';
            case 'Shower sleet':
              return 'Chuva de neve';
            case 'Light rain and snow':
              return 'Chuva leve e neve';
            case 'Rain and snow':
              return 'Chuva e neve';
            case 'Light shower snow':
              return 'Chuva de neve leve';
            case 'Shower snow':
              return 'Chuva de neve';
            case 'Heavy shower snow':
              return 'Neve pesada';
            case 'mist':
              return 'Névoa';
            case 'Smoke':
              return 'Enfumaçado';
            case 'Haze':
              return 'Neblina';
            case 'sand/ dust whirls':
              return 'Areia/redemoinhos';
            case 'fog':
              return 'Névoa';
            case 'sand':
              return 'Areia';
            case 'dust':
              return 'Poeira';
            case 'volcanic ash':
              return 'Cinza vulcanica';
            case 'squalls':
              return 'Rajadas';
            case 'tornado':
              return 'Tornado';
            case 'clear sky':
              return 'Céu limpo';
            case 'few clouds':
              return 'Poucas nuvens';
            case 'scattered clouds':
              return 'Nuvens dispersas';
            case 'broken clouds':
              return 'Nuvens dispersas';
            case 'overcast clouds':
              return 'Nuvens nubladas';
          }
        }
      };
      vm.finance = {
        symbols: [
          {
            key: 'dolar',
            label: 'Dolar',
            symbol: 'USD',
            value: 'buy'
          },
          {
            key: 'euro',
            label: 'Euro',
            symbol: 'EUR',
            value: 'buy'
          },
          {
            key: 'bitcoin',
            label: 'Bitcoin',
            symbol: 'BTC',
            value: 'buy'
          },
          {
            key: 'ibovespa',
            label: 'IBOVESPA',
            symbol: 'IBOVESPA',
            value: 'points'
          },
          {
            key: 'nasdaq',
            label: 'NASDAQ',
            symbol: 'NASDAQ',
            value: 'points'
          }
        ],
        // url: 'https://economia.awesomeapi.com.br/all/USD-BRL,EUR-BRL,BTC-BRL'
        keys: ['1d55022f',
    'e2ea071f',
    'd9f8b16b',
    'b863ff04',
    'ba0e2932'],
        url: 'http://api.hgbrasil.com/finance?format=json-cors&key=b863ff04',
        get: function() {
          var error,
    success;
          if (this.loading) {
            return;
          }
          this.loading = true;
          success = (resp) => {
            this.loading = false;
            this.loaded = true;
            console.log('Finance data:',
    resp.data);
            return this.handleHgb(resp.data);
          };
          error = (resp) => {
            this.loading = false;
            return console.error('Finance:',
    resp);
          };
          return $http.get(this.url).then(success,
    error);
        },
        handleHgb: function(dataObj) {
          var currencies,
    i,
    item,
    len,
    ref,
    stocks,
    sym;
          if (!dataObj) {
            return;
          }
          currencies = dataObj.results.currencies;
          stocks = dataObj.results.stocks;
          this.data || (this.data = {});
          ref = this.symbols;
          for (i = 0, len = ref.length; i < len; i++) {
            sym = ref[i];
            item = currencies[sym.symbol] || stocks[sym.symbol];
            if (!item) {
              continue;
            }
            this.data[sym.key] = {
              valor: item[sym.value],
              variacao: item.variation
            };
          }
          console.log('FINANCE ->',
    this.data);
        }
      };
      return vm;
    }
  ]);

}).call(this);
