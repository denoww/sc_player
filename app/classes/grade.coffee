fs      = require 'fs'
request = require 'request'

module.exports = ->
  ctrl =
    data: {}
    getList: ->
      url = "#{ENV.API_SERVER_URL}/publicidades/grade.json?id=#{ENV.TV_ID}"

      request url, (error, response, body)=>
        if error || response?.statusCode != 200
          erro = 'Request Failed.'
          erro += " Status Code: #{response.statusCode}." if response?.statusCode
          erro += " #{error}" if error
          console.error erro
          @getDataOffline()
          return

        data = JSON.parse(body)
        return console.error 'Erro: Não existe Dados da Grade!' unless data
        @handlelist(data)
        @saveDataJson()
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

      fs.writeFile 'playlist.json', dados, (error)->
        return console.error error if error
        console.info 'Grade -> playlist.json salvo com sucesso!'
      return
    getDataOffline: ->
      console.info 'Grade -> Pegando grade de playlist.json'
      try
        @data = JSON.parse(fs.readFileSync('playlist.json', 'utf8') || '{}')
        @data.offline = true
        global.feeds.getList()
      catch e
        console.error 'Grade -> getDataOffline:', e

  setInterval ->
    console.info 'Grade -> Atualizando lista!'
    ctrl.getList()
  , 1000 * 60 * ENV.TEMPO_ATUALIZAR

  ctrl.getList()
  global.grade = ctrl
