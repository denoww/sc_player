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
    create: (message, opts={})->
      return if !message
      console.info message

      # enviando log para o Sentry
      Sentry.log message, opts if opts.send

      return if ENV.NODE_ENV != 'development'
      log = (new Date).toLocaleString() + ' :: ' + message
      shell.exec "echo '#{log}' >> #{@caminho}", (code, grepOut, grepErr)->
        return console.error 'Logs -> create:', grepErr if grepErr
      return
    info: (message, opts={})->
      opts.send  = true
      opts.level = 'info'
      @create message, opts
    debug: (message, opts={})->
      opts.send  = true
      opts.level = 'debug'
      @create message, opts
    error: (message, opts={})->
      opts.send  = true
      opts.level = 'error'
      @create message, opts
    fatal: (message, opts={})->
      opts.send  = true
      opts.level = 'fatal'
      @create message, opts
    warning: (message, opts={})->
      opts.send  = true
      opts.level = 'warning'
      @create message, opts
  ctrl.init()
  global.logs = ctrl
