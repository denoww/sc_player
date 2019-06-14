app = angular.module('publicidade_app', ['ngSanitize', 'ngLocale'])

app.config ['$qProvider', ($qProvider)->
    $qProvider.errorOnUnhandledRejections(false)
]

app.controller('MainCtrl', [
  '$http', '$timeout'
  ($http, $timeout)->
    vm = @
    vm.loading = true

    vm.init = ->
      vm.loading = true

      vm.grade.get ->
        vm.feeds.get ->
          vm.loading = false
          vm.loaded = true
          vm.relogio()

      vm.weather.get()
      vm.finance.get()

      setInterval ->
        vm.grade.get -> vm.feeds.get()
        vm.weather.get()
      , 1000 * 60  # a cada minuto

      setInterval ->
        vm.finance.get()
      , 1000 * 60 * 5 # a cada 5 minutos

    vm.timeline =
      tipos:     ['conteudos', 'musicas', 'mensagens']
      current:   {}
      promessa:  {}
      nextIndex: {}
      transicao: {}
      init: ->
        return unless vm.loaded

        for tipo in @tipos
          @nextIndex[tipo] ||= 0
          @executar(tipo)
          @executar(tipo) if @promessa?[tipo]?.$$state?.status != 0
      executar: (tipo)->
        @transicao[tipo] = false
        $timeout.cancel(@promessa[tipo]) if @promessa?[tipo]

        @current[tipo] = @getNextItem(tipo)
        return unless @current[tipo]

        segundos = (@current[tipo].segundos * 1000) || 5000
        vm.timeline.transicao[tipo] = true
        $timeout (-> vm.timeline.transicao[tipo] = false), 250
        $timeout (-> vm.timeline.transicao[tipo] = true), segundos - 250
        @promessa[tipo] = $timeout (-> vm.timeline.next(tipo)), segundos
        return
      getNextItem: (tipo)->
        lista = (vm.grade.data[tipo] || []).select (e)-> e.ativado
        return unless lista.length

        index = @nextIndex[tipo]
        index = 0 if index >= lista.length

        @nextIndex[tipo]++
        @nextIndex[tipo] = 0 if @nextIndex[tipo] >= lista.length

        currentItem = lista[index]
        if currentItem.tipo_midia != 'feed'
          return currentItem
        @getItemFeed(currentItem)
      getItemFeed: (currentItem)->
        feedItems = vm.feeds.data[currentItem.fonte]?[currentItem.categoria]
        return currentItem if (feedItems || []).empty()

        fonte = currentItem.fonte
        categ = currentItem.categoria
        vm.feeds.nextIndex[fonte] ||= {}

        if !vm.feeds.nextIndex[fonte][categ]?
          vm.feeds.nextIndex[fonte][categ] = 0
        else
          vm.feeds.nextIndex[fonte][categ]++

        if vm.feeds.nextIndex[fonte][categ] >= feedItems.length
          vm.feeds.nextIndex[fonte][categ] = 0

        feedIndex = vm.feeds.nextIndex[fonte][categ]

        feed = feedItems[feedIndex] || feedItems[0]

        return unless feed
        currentItem.nome   = feed.nome
        currentItem.data   = feed.data
        currentItem.titulo = feed.titulo
        currentItem.titulo_feed = feed.titulo_feed

        currentItem
      next: (tipo)->
        @current[tipo] = {}
        $timeout -> vm.timeline.executar(tipo)

    vm.grade =
      data: {}
      tentar: 10
      tentativas: 0
      get: (onSuccess, onError)->
        return if @loading
        @loading = true

        success = (resp)=>
          @loading    = false
          @tentativas = 0
          vm.offline  = resp.data.offline

          @data = resp.data
          onSuccess?()
          vm.timeline.init()

        error = (resp)=>
          @loading = false
          vm.timeline.init()
          console.error 'Grade:', resp

          @tentativas++
          if @tentativas > @tentar
            console.error 'Grade: Não foi possível comunicar com o servidor!'
            return

          @tentarNovamenteEm = 1000 * @tentativas
          console.warn "Grade: Tentando em #{@tentarNovamenteEm} segundos"
          $timeout (-> vm.grade.get()), @tentarNovamenteEm
          onError?()

        $http(method: 'GET', url: '/grade').then success, error
        return

    vm.feeds =
      data: {}
      tentar: 10
      tentativas: 0
      nextIndex: {}
      get: (onSuccess, onError)->
        return if @loading
        @loading = true

        success = (resp)=>
          @loading    = false
          @tentativas = 0

          @data = resp.data
          @verificarNoticias()
          onSuccess?()
          vm.timeline.init()

        error = (resp)=>
          @loading = false
          vm.timeline.init()
          console.error 'Feeds:', resp

          @tentativas++
          if @tentativas > @tentar
            console.error 'Feeds: Não foi possível comunicar com o servidor!'
            return

          @tentarNovamenteEm = 1000 * @tentativas
          console.warn "Feeds: Tentando em #{@tentarNovamenteEm} segundos"
          $timeout (-> vm.feeds.get()), @tentarNovamenteEm
          onError?()

        $http(method: 'GET', url: '/feeds').then success, error
        return
      verificarNoticias: ->
        for fonte, categorias of @data
          for categoria, valores of categorias
            if (valores?.lista || []).empty()
            if (valores || []).empty()
              return unless vm.grade.data.conteudos
              conteudos = vm.grade.data.conteudos.select (e)->
                e.fonte == fonte && e.categoria == categoria
              cont.ativado = false for cont in conteudos
        return

    vm.mouse =
      onMove: ->
        $timeout.cancel(@timeout) if @timeout
        document.body.style.cursor = 'default'

        @timeout = $timeout =>
          document.body.style.cursor = 'none'
        , 1000

    vm.relogio = ->
      vm.now = new Date
      hour = vm.now.getHours()
      min  = vm.now.getMinutes()
      sec  = vm.now.getSeconds()

      hour = "#{hour}".rjust(2, '0')
      min  = "#{min}".rjust(2, '0')
      sec  = "#{sec}".rjust(2, '0')

      elem = document.getElementById('hora')
      elem.innerHTML = hour + ':' + min + ':' + sec if elem
      setTimeout vm.relogio, 1000
      return

    vm.weather =
      apiKey: '163e87549d7123a2f1ee5d6ba165e40f'
      url: 'http://api.openweathermap.org/data/2.5/weather?units=metric'
      get: ->
        return if @loading
        @loading = true

        vm.lat = -16.686902
        vm.lon = -49.264788

        success = (resp)=>
          @loading = false
          @loaded = true
          @handle(resp.data)

        error = (resp)=>
          @loading = false
          console.error 'Weather:', resp

        url = "#{@url}&lat=#{vm.lat}&lon=#{vm.lon}&appid=#{@apiKey}"
        $http(method: 'GET', url: url).then success, error
      handle: (dataObj)->
        return unless dataObj
        @data ||= {}

        if dataObj.main.temp
          @data.temperatura = parseInt dataObj.main.temp

        if dataObj.main.humidity
          @data.umidade = parseInt dataObj.main.humidity

        if (dataObj.weather || []).any()
          weather = dataObj.weather[0]
          @data.icone     = @getIcon(weather.icon)
          @data.descricao = @getDescricao(weather.description)

        if dataObj.wind.speed
          # m/s * 3.6 = km/h
          @data.vento = Math.ceil(dataObj.wind.speed * 3.6)
        return
      getIcon: (icon)->
        icone = switch true
          when /01/.test(icon) then 'clear_sky'
          when /02/.test(icon) then 'few_clouds'
          when /03/.test(icon) then 'scattered_clouds'
          when /04/.test(icon) then 'broken_clouds'
          when /09/.test(icon) then 'shower_rain'
          when /10/.test(icon) then 'rain'
          when /11/.test(icon) then 'thunderstorm'
          when /13/.test(icon) then 'snow'
          when /50/.test(icon) then 'mist'
          else 'few_clouds'

        icone += '_n' if icon.match /\d{2}n/
        icone
      getDescricao: (desc)->
        switch desc
          when 'thunderstorm with light rain'    then 'Trovoada com chuva'
          when 'thunderstorm with rain'          then 'Trovoada com chuva'
          when 'thunderstorm with heavy rain'    then 'Trovoada com chuva'
          when 'light thunderstorm'              then 'Trovoada e relâmpagos'
          when 'thunderstorm'                    then 'Trovoada'
          when 'heavy thunderstorm'              then 'Trovoada pesada'
          when 'ragged thunderstorm'             then 'Trovoada irregular'
          when 'thunderstorm with light drizzle' then 'Trovoada com leve garoa'
          when 'thunderstorm with drizzle'       then 'Trovoada com chuvisco'
          when 'thunderstorm with heavy drizzle' then 'Trovoada com chuva'
          when 'light intensity drizzle'         then 'Chuvisco leve'
          when 'drizzle'                         then 'Chuvisco'
          when 'heavy intensity drizzle'         then 'Chuvisco forte'
          when 'light intensity drizzle rain'    then 'Chuva leve'
          when 'drizzle rain'                    then 'Chuva'
          when 'heavy intensity drizzle rain'    then 'Chuva forte'
          when 'shower rain and drizzle'         then 'Chuva e chuvisco'
          when 'heavy shower rain and drizzle'   then 'Chuva forte'
          when 'shower drizzle'                  then 'Chuvisco'
          when 'light rain'                      then 'Chuva leve'
          when 'moderate rain'                   then 'Chuva moderada'
          when 'heavy intensity rain'            then 'Chuva intensa'
          when 'very heavy rain'                 then 'Chuva muito forte'
          when 'extreme rain'                    then 'Chuva extrema'
          when 'freezing rain'                   then 'Chuva'
          when 'light intensity shower rain'     then 'Chuva leve'
          when 'shower rain'                     then 'Chuva de banho'
          when 'heavy intensity shower rain'     then 'Chuva forte'
          when 'ragged shower rain'              then 'Chuva irregular'
          when 'light snow'                      then 'Pouca neve'
          when 'Snow'                            then 'Neve'
          when 'Heavy snow'                      then 'Neve pesada'
          when 'Sleet'                           then 'Chuva com neve'
          when 'Light shower sleet'              then 'Chuva de granizo'
          when 'Shower sleet'                    then 'Chuva de neve'
          when 'Light rain and snow'             then 'Chuva leve e neve'
          when 'Rain and snow'                   then 'Chuva e neve'
          when 'Light shower snow'               then 'Chuva de neve leve'
          when 'Shower snow'                     then 'Chuva de neve'
          when 'Heavy shower snow'               then 'Neve pesada'
          when 'mist'                            then 'Névoa'
          when 'Smoke'                           then 'Enfumaçado'
          when 'Haze'                            then 'Neblina'
          when 'sand/ dust whirls'               then 'Areia/redemoinhos'
          when 'fog'                             then 'Névoa'
          when 'sand'                            then 'Areia'
          when 'dust'                            then 'Poeira'
          when 'volcanic ash'                    then 'Cinza vulcanica'
          when 'squalls'                         then 'Rajadas'
          when 'tornado'                         then 'Tornado'
          when 'clear sky'                       then 'Céu limpo'
          when 'few clouds'                      then 'Poucas nuvens'
          when 'scattered clouds'                then 'Nuvens dispersas'
          when 'broken clouds'                   then 'Nuvens dispersas'
          when 'overcast clouds'                 then 'Nuvens nubladas'

    vm.finance =
      symbols: [
        { key: 'dolar',    label: 'Dolar',    symbol: 'USD',      value: 'buy'}
        { key: 'euro',     label: 'Euro',     symbol: 'EUR',      value: 'buy'}
        { key: 'bitcoin',  label: 'Bitcoin',  symbol: 'BTC',      value: 'buy'}
        { key: 'ibovespa', label: 'IBOVESPA', symbol: 'IBOVESPA', value: 'points'}
        { key: 'nasdaq',   label: 'NASDAQ',   symbol: 'NASDAQ',   value: 'points'}
      ]
      keys: ['1d55022f', 'e2ea071f', 'd9f8b16b', 'b863ff04', 'ba0e2932']
      url: 'http://api.hgbrasil.com/finance?format=json-cors&key=b863ff04'
      get: ->
        return if @loading
        @loading = true

        success = (resp)=>
          @loading = false
          @loaded = true
          @handleHgb(resp.data)

        error = (resp)=>
          @loading = false
          console.error 'Finance:', resp

        $http.get(@url).then success, error
      handleHgb: (dataObj)->
        return unless dataObj
        currencies = dataObj.results.currencies
        stocks     = dataObj.results.stocks
        @data ||= {}

        for sym in @symbols
          item = currencies[sym.symbol] || stocks[sym.symbol]
          continue unless item

          @data[sym.key] = valor: item[sym.value], variacao: item.variation
        return

    vm
])

