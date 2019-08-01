# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, BrowserWindow, crashReporter } = require 'electron'
contextMenu = require 'electron-context-menu'

Sentry = require('@sentry/node')
Sentry.init({ dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364' })

crashReporter.start
  productName: 'sc_player'
  companyName: 'seucondominio'
  submitURL: 'https://sentry.io/api/1519364/minidump/?sentry_key=ac78f87fac094b808180f86ad8867f61'
  autoSubmit: true

createWindow = ->
  win = new BrowserWindow
    show:            false
    icon:            "#{__dirname}/app/assets/images/icon.png"
    kiosk:           true
    minWidth:        640
    minHeight:       360
    darkTheme:       true
    autoplayPolicy:  'no-user-gesture-required'
    useContentSize:  true
    autoHideMenuBar: true
    backgroundColor: '#222'
    webPreferences:
      webSecurity:     false
      nodeIntegration: true

  win.loadURL 'http://localhost:3001'
  win.focus()
  win.once 'ready-to-show', -> win.show()
  global.win = win

  win.webContents.on 'crashed', (e, c)->
    global.logs.create('--- WEBCONTENTS --- crashed ->', e, c)
    global.logs.create('--- RELOADING.........')
    setTimeout (-> win.reload()), 1000

  # Open the DevTools
  # win.webContents.openDevTools()

contextMenu(
  prepend: (defaultActions, params, browserWindow)->
    [
      { role: 'toggleFullScreen', label: 'Fullscreen' }
      { type: 'separator' }
      { role: 'reload', label: 'Atualizar Player' }
      {
        label: 'Reiniciar Player',
        click: ->
          app.relaunch({ args: process.argv.slice(1).concat(['--relaunch']) })
          app.exit(0)
      }
      { type: 'separator' }
      {
        label: 'Atualizar Equipamento',
        click: ->
          app.relaunch({ args: process.argv.slice(1).concat(['--relaunch']) })
          app.exit(0)
      }
      {
        label: 'Reiniciar Equipamento',
        click: ->
          global.grade.restartPlayer()
      }
    ]
)

app.setName 'SC Player'

app.on 'ready', createWindow
