# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, dialog, BrowserWindow } = require 'electron'
contextMenu = require 'electron-context-menu'

# Sentry = require('@sentry/node')
Sentry = require('@sentry/electron')
Sentry.init dsn: 'https://ac78f87fac094b808180f86ad8867f61@sentry.io/1519364'
Sentry.configureScope (scope)->
  scope.setUser id: "TV_ID_#{ENV.TV_ID}"

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

  win.webContents.on 'crashed', (event, killed)->
    global.logs.create('--- WEBCONTENTS --- crashed', event, killed)

    error        = new Error "TV_ID_#{ENV.TV_ID}_BACKEND"
    error.event  = event
    error.killed = killed
    Sentry.captureException(error)

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
          global.grade.updatePlayer()
      }
      {
        label: 'Reiniciar Equipamento',
        click: ->
          global.grade.restartPlayer()
      }
    ]
)

# Disable error dialogs by overriding
dialog.showErrorBox = (title, content)->
  global.logs.create("DIALOG -> #{title} #{content}")
  error         = new Error "DIALOG_TV_ID_#{ENV.TV_ID}"
  error.title   = title
  error.content = content
  Sentry.captureException(error)

app.setName 'SC Player'

app.on 'ready', createWindow
