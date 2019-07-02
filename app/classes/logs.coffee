shell   = require 'shelljs'
resolve = require('path').resolve

module.exports = ->
  ctrl =
    init: ->
      @caminho = resolve('./logs')
    show: ->
      shell.exec "cat #{@caminho}", (code, grepOut, grepErr)->
        return console.error 'Logs -> show:', grepErr if grepErr
        console.log 'LOGS:', grepOut
        grepOut
    create: (message)->
      return unless message
      log = (new Date).toISOString() + ' >> ' + message
      shell.exec "echo '#{log}' >> #{@caminho}", (code, grepOut, grepErr)->
        return console.error 'Logs -> create:', grepErr if grepErr
  ctrl.init()
  global.logs = ctrl
