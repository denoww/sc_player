express = require 'express'
resolve = require('path').resolve

module.exports = (opt={}) ->
  app = express()
  server = app.listen(ENV.HTTP_PORT)
  console.info "HTTP #{ENV.HTTP_PORT} STARTING"

  app.use express.static(resolve('app/assets/'))
  app.use '/downloads/', express.static(resolve('downloads/'))

  # Resolve o erro do CROSS de Access-Control-Allow-Origin
  app.all '*', (req, res, next)->
    res.header 'Content-Type', 'application/json'
    res.header 'Access-Control-Allow-Origin', '*'
    res.header 'Access-Control-Allow-Methods', 'OPTIONS,GET,POST,PUT,DELETE'
    res.header 'Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With'
    return res.sendStatus(200) if req.method == 'OPTIONS'
    next()

  app.get '/', (req, res) ->
    console.info "Request GET / params: #{JSON.stringify(req.body || {})}"
    res.type "text/html"
    res.sendFile resolve('app/assets/templates/index.html')

  app.get '/grade', (req, res) ->
    console.info "Request GET /grade params: #{JSON.stringify(req.body || {})}"
    if Object.empty global.grade.data
      global.grade.getList()
      res.sendStatus(400)
      return
    global.grade.setTimerUpdateBrowser()
    res.send JSON.stringify global.grade.data

  app.get '/feeds', (req, res) ->
    console.info "Request GET /feeds params: #{JSON.stringify(req.body || {})}"
    if Object.any global.grade.data && Object.empty global.feeds.data
      global.feeds.getList()
      res.sendStatus(400)
      return
    res.send JSON.stringify global.feeds.data
