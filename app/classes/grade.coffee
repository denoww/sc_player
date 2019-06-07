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
        @salvarJson()
        global.feeds.getList()
    handlelist: (data)->
      @data =
        id:        data.id
        layout:    data.layout
        musicas:   []
        conteudos: []
        mensagens: []
        resolucao: data.resolucao

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
          when 'mensagem'        then @handleMensagem(vinculo, item)
          when 'clima'           then @handleClima(vinculo, item)
          when 'feed'            then @handleFeed(vinculo, item)
      return
    handleMidia: (vinculo, item)->
      return unless vinculo.midia

      item.url      = vinculo.midia.original
      item.nome     = "#{vinculo.midia.id}.#{vinculo.midia.extension}"
      item.size     = vinculo.midia.size
      item.midia_id = vinculo.midia.id
      item.extensao = vinculo.midia.extension
      item.is_audio = vinculo.midia.is_audio
      item.is_image = vinculo.midia.is_image
      item.is_video = vinculo.midia.is_video

      if item.is_audio
        @data.musicas.push item
      else
        @data.conteudos.push item
      Download.exec(item)
    handleMensagem: (vinculo, item)->
      return unless vinculo.mensagem

      item.mensagem = vinculo.mensagem.texto
      @data.mensagens.push item
    handleClima: (vinculo, item)->
      return unless vinculo.clima

      item.uf      = vinculo.clima.uf
      item.nome    = vinculo.clima.nome
      item.country = vinculo.clima.country
      @data.conteudos.push item
    handleFeed: (vinculo, item)->
      return unless vinculo.feed

      item.url       = vinculo.feed.url
      item.fonte     = vinculo.feed.fonte
      item.categoria = vinculo.feed.categoria
      @data.conteudos.push item
    salvarJson: ->
      dados = JSON.stringify @data, null, 2

      fs.writeFile 'playlist.json', dados, (error)->
        return console.error error if error
        console.info 'Grade -> playlist.json salvo com sucesso!'
      return
    getDataOffline: ->
      console.info 'Grade -> Pegando grade de playlist.json'
      try
        @data = JSON.parse(fs.readFileSync('playlist.json', 'utf8'))
        global.feeds.getList()
      catch e
        console.error 'Grade -> getDataOffline:', e

  ctrl.getList()
  global.grade = ctrl
