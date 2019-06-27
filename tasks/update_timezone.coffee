shell   = require 'shelljs'
request = require 'request'

do ->
  url = 'http://ip-api.com/json'
  console.info '>> Atualizando Timezone!'
  console.info "URL", url

  request url, (error, response, body)=>
    if error || response?.statusCode != 200
      erro = 'Request Failed.'
      erro += " Status Code: #{response.statusCode}." if response?.statusCode
      erro += " #{error}" if error
      console.error erro
      return

    data = JSON.parse(body)
    console.log 'data', data.timezone
    return unless data.timezone

    command = "sudo ln -f -s /usr/share/zoneinfo/#{data.timezone} /etc/localtime"
    shell.exec command, (code, out, error)->
      return console.log 'Timezone -> Error:', error if error
      console.log 'Timezone atualizado!'
  return
