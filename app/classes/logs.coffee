shell  = require 'shelljs'
Sentry = require './sentry'

module.exports = ->
  ctrl =
    init: ->
      @caminho = global.configPath + 'logs'
    show: ->
      shell.exec "cat #{@caminho}", (code, grepOut, grepErr)->
        return console.error 'Logs -> show:', grepErr if grepErr
        console.log 'LOGS:', grepOut
        grepOut
    create: (message, options={})->
      return if !message
      console.info message

      # enviando log para o Sentry
      Sentry.log message, options if options.send

      return if ENV.NODE_ENV != 'development'
      log = (new Date).toLocaleString() + ' :: ' + message
      shell.exec "echo '#{log}' >> #{@caminho}", (code, grepOut, grepErr)->
        return console.error 'Logs -> create:', grepErr if grepErr
      return
    info: (message, options={})->
      options.send  = true
      options.level = 'info'
      @create message, options
    debug: (message, options={})->
      options.send  = true
      options.level = 'debug'
      @create message, options
    error: (message, options={})->
      options.send  = true
      options.level = 'error'
      @create message, options
    fatal: (message, options={})->
      options.send  = true
      options.level = 'fatal'
      @create message, options
    warning: (message, options={})->
      options.send  = true
      options.level = 'warning'
      @create message, options
  ctrl.init()
  global.logs = ctrl
