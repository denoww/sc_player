fs      = require 'fs'
shell   = require 'shelljs'
request = require 'request'
resolve = require('path').resolve

module.exports = ->
  ctrl =
    data: {}
    getList: ->
      url = "#{ENV.API_SERVER_URL}/publicidades/grade.json?id=#{ENV.TV_ID}"
      console.info "URL", url

      request url, (error, response, body)=>
        @getDataOffline()

        if error || response?.statusCode != 200
          erro = 'Request Failed.'
          erro += " Status Code: #{response.statusCode}." if response?.statusCode
          erro += " #{error}" if error
          global.logs.create("Grade -> getList -> ERRO: #{erro}")
          return

        data = JSON.parse(body)
        if Object.empty(data || {})
          return global.logs.create('Grade -> Erro: Não existe Dados da Grade!')

        atualizarPlayer = @data?.versao_player? &&
          @data.versao_player != data.versao_player

        @handlelist(data)
        @saveDataJson()

        if atualizarPlayer
          return @updatePlayer()

        global.feeds.getList()
    handlelist: (data)->
      @data =
        id:        data.id
        cor:       data.cor
        layout:    data.layout
        cidade:    data.cidade
        musicas:   []
        conteudos: []
        mensagens: []
        resolucao: data.resolucao
        versao_player: data.versao_player

      @data.finance = data.finance if data.finance
      @data.weather = data.weather if data.weather

      for vinculo in (data.vinculos || []).sortByField('ordem')
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
          when 'playlist'        then @handlePlaylist(vinculo, item)
          when 'mensagem'        then @handleMensagem(vinculo, item)
          when 'clima'           then @handleClima(vinculo, item)
          when 'feed'            then @handleFeed(vinculo, item)
      return
    handleMidia: (vinculo, item, lista=null)->
      return unless vinculo.midia

      item.url      = vinculo.midia.original
      item.nome     = "#{vinculo.midia.id}.#{vinculo.midia.extension}"
      item.size     = vinculo.midia.size
      item.midia_id = vinculo.midia.id
      item.extensao = vinculo.midia.extension
      item.is_audio = vinculo.midia.is_audio
      item.is_image = vinculo.midia.is_image
      item.is_video = vinculo.midia.is_video
      item.content_type = vinculo.midia.content_type

      lista ||= @data

      if item.is_audio
        lista.musicas.push item
      else
        lista.conteudos.push item
      Download.exec(item)
    handlePlaylist: (vinculo, item)->
      return unless (vinculo.playlist.vinculos || []).any()
      item.conteudos = []

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
      @data.conteudos.push item
    handleMensagem: (vinculo, item)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem.texto
      @data.mensagens.push item
    handleClima: (vinculo, item, lista=null)->
      return unless vinculo.clima
      lista ||= @data

      item.uf      = vinculo.clima.uf
      item.nome    = vinculo.clima.nome
      item.country = vinculo.clima.country
      lista.conteudos.push item
    handleFeed: (vinculo, item, lista=null)->
      return unless vinculo.feed
      lista ||= @data

      item.url       = vinculo.feed.url
      item.fonte     = vinculo.feed.fonte
      item.categoria = vinculo.feed.categoria
      lista.conteudos.push item
    saveDataJson: ->
      dados = JSON.stringify @data, null, 2
      try
        fs.writeFile 'grade.json', dados, (error)->
          if error
            return global.logs.create("Grade -> saveDataJson -> ERRO: #{error}")
          console.info 'Grade -> grade.json salvo com sucesso!'
      catch e
        global.logs.create("Grade -> saveDataJson -> ERRO: #{e}")
      return
    getDataOffline: ->
      console.info 'Grade -> Pegando grade de grade.json'
      try
        @data = JSON.parse(fs.readFileSync('grade.json', 'utf8') || '{}')
        @data.offline = true
      catch e
        global.logs.create("Grade -> getDataOffline -> ERRO: #{e}")
    updatePlayer: ->
      global.logs.create('Grade -> Atualizando Player!')
      # se a versao do player for alterada sera executado a atualizacao

      caminho = resolve('tasks/')
      shell.exec "#{caminho}./update.sh", (code, grepOut, grepErr)->
        if grepErr
          global.logs.create("Grade -> updatePlayer -> ERRO: #{grepErr}")

  setInterval ->
    console.info 'Grade -> Atualizando lista!'
    ctrl.getList()
  , 1000 * 60 * ENV.TEMPO_ATUALIZAR

  ctrl.getList()
  global.grade = ctrl
