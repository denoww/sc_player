fs      = require 'fs'
path    = require 'path'
shell   = require 'shelljs'
request = require 'request'

module.exports = ->
  ctrl =
    data: {}
    getList: ->
      url = "#{ENV.API_SERVER_URL}/publicidades/grade.json?id=#{ENV.TV_ID}"
      global.logs.create "URL: #{url}"

      @getDataOffline()
      @data.offline = true

      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          erro = 'Request Failed.'
          erro += " Status Code: #{response.statusCode}." if response?.statusCode
          erro += " #{error}" if error
          global.logs.warning "Grade -> getList -> #{erro}", tags: class: 'grade'
          global.feeds.getList()
          return

        @data.offline = false
        jsonData = JSON.parse(body)
        if Object.empty(jsonData || {})
          return global.logs.create 'Grade -> Erro: Não existe Dados da Grade!'

        atualizarPlayer = @data?.versao_player? &&
          @data.versao_player != jsonData.versao_player

        @handlelist(jsonData)
        @saveLogo(jsonData.logo_url)
        @saveDataJson()

        if atualizarPlayer
          return global.versionsControl.init()

        global.feeds.getList()
        @setTimerUpdateWindow()
    handlelist: (jsonData)->
      configPath = global.configPath
      configPath = configPath.split('\\').join('/') if process.platform == 'win32'

      @data =
        id:        jsonData.id
        cor:       jsonData.cor
        path:      configPath
        layout:    jsonData.layout
        cidade:    jsonData.cidade
        offline:   false
        resolucao: jsonData.resolucao
        informacoes: jsonData.informacoes
        versao_player: jsonData.versao_player

      @data.finance = jsonData.finance if jsonData.finance
      @data.weather = jsonData.weather if jsonData.weather

      for vinculo in (jsonData.vinculos || []).sortByField('ordem')
        continue unless vinculo.ativado

        item =
          id:         vinculo.id
          ordem:      vinculo.ordem
          titulo:     vinculo.titulo
          ativado:    vinculo.ativado
          horarios:   vinculo.horarios
          segundos:   vinculo.segundos
          tipo_midia: vinculo.tipo_midia

        switch vinculo.tipo_midia
          when 'musica', 'midia' then @handleMidia(vinculo, item)
          when 'informativo'     then @handleInformativo(vinculo, item)
          when 'playlist'        then @handlePlaylist(vinculo, item)
          when 'mensagem'        then @handleMensagem(vinculo, item)
          when 'clima'           then @handleClima(vinculo, item)
          when 'feed'            then @handleFeed(vinculo, item)
      return
    handleMidia: (vinculo, item, lista=null)->
      return unless vinculo.midia

      item.url      = vinculo.midia.original
      item.size     = vinculo.midia.size
      item.midia_id = vinculo.midia.id
      item.extensao = vinculo.midia.extension
      item.is_audio = vinculo.midia.is_audio
      item.is_image = vinculo.midia.is_image
      item.is_video = vinculo.midia.is_video
      item.content_type = vinculo.midia.content_type
      item.nome_arquivo = "#{vinculo.midia.id}.#{vinculo.midia.extension}"

      lista ||= @data
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      Download.exec(item)
      return
    handleInformativo: (vinculo, item, lista=null)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem
      lista ||= @data
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handlePlaylist: (vinculo, item)->
      return unless (vinculo.playlist.vinculos || []).any()

      for vinc in (vinculo.playlist.vinculos || []).sortByField('ordem')
        continue unless vinc.ativado

        subItem =
          id:         vinc.id
          ordem:      vinc.ordem
          titulo:     vinc.titulo
          ativado:    vinc.ativado
          horarios:   vinc.horarios
          segundos:   vinc.segundos
          tipo_midia: vinc.tipo_midia

        switch vinc.tipo_midia
          when 'midia' then @handleMidia(vinc, subItem, item)
          when 'clima' then @handleClima(vinc, subItem, item)
          when 'feed'  then @handleFeed(vinc, subItem, item)
          when 'informativo' then @handleInformativo(vinc, subItem, item)

      @data[vinculo.posicao] ||= []
      @data[vinculo.posicao].push item
      return
    handleMensagem: (vinculo, item)->
      return unless vinculo.mensagem
      item.mensagem = vinculo.mensagem.texto

      @data[vinculo.posicao] ||= []
      @data[vinculo.posicao].push item
      return
    handleClima: (vinculo, item, lista=null)->
      return unless vinculo.clima
      lista ||= @data

      item.uf      = vinculo.clima.uf
      item.nome    = vinculo.clima.nome
      item.country = vinculo.clima.country
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    handleFeed: (vinculo, item, lista=null)->
      return unless vinculo.feed
      lista ||= @data

      item.url       = vinculo.feed.url
      item.fonte     = vinculo.feed.fonte
      item.categoria = vinculo.feed.categoria
      lista[vinculo.posicao] ||= []
      lista[vinculo.posicao].push item
      return
    saveLogo: (logoUrl)->
      return @data.logo_nome = null unless logoUrl

      extension = logoUrl.match(/\.jpg|\.jpeg|\.png|\.gif|\.webp/i)?[0] || ''
      imageNome = logoUrl.split('/').pop().replace(extension, '').removeSpecialCharacters()
      imageNome = "#{imageNome}#{extension}"
      @data.logo_nome = imageNome

      params =
        url: logoUrl
        is_logo: true
        nome_arquivo: imageNome

      Download.exec(params)
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'grade.json', dados, (error)->
          return global.logs.error "Grade -> saveDataJson -> #{error}", tags: class: 'grade' if error
          global.logs.create 'Grade -> grade.json salvo com sucesso!'
      catch e
        global.logs.error "Grade -> saveDataJson -> #{e}", tags: class: 'grade'
      return
    getDataOffline: ->
      global.logs.create 'Grade -> Pegando grade de grade.json'
      try
        @data = JSON.parse(fs.readFileSync('grade.json', 'utf8') || '{}')
      catch e
        global.logs.error "Grade -> getDataOffline -> #{e}", tags: class: 'grade'
      return
    refreshWindow: ->
      # atualizar o app para limpar cache e sobrecarga de processos
      global.win?.reload?()
    setTimerUpdateWindow: ->
      # caso o app pare de receber requisições será atualizado
      @clearTimerUpdateWindow()
      @timerUpdateWindow = setTimeout ->
        global.logs.create 'Grade -> Atualizando Aplicação! :('
        ctrl.refreshWindow()
      , 1000 * 60 * 2.5 # 2.5 minutos
    clearTimerUpdateWindow: ->
      clearTimeout @timerUpdateWindow if @timerUpdateWindow

  setInterval ->
    global.logs.create 'Grade -> Atualizando lista!'
    ctrl.getList()
  , 1000 * 60 * (ENV.TEMPO_ATUALIZAR || 5)

  setInterval ->
    global.logs.info 'Grade -> Atualização preventiva (3h)!', tags: class: 'grade'
    ctrl.refreshWindow()
  , 1000 * 60 * 60 * 3 # 3 horas

  ctrl.getList()
  global.grade = ctrl
