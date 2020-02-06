# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, dialog, BrowserWindow } = require 'electron'
contextMenu = require 'electron-context-menu'
shell = require 'shelljs'

createWindow = ->
  windowOptions =
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

  if ENV.NODE_ENV == 'development'
    windowOptions.kiosk       = false
    windowOptions.width       = 640
    windowOptions.height      = 360
    windowOptions.alwaysOnTop = true

  win = new BrowserWindow windowOptions

  win.loadURL 'http://localhost:3001'
  win.focus()
  win.once 'ready-to-show', -> win.show()
  global.win = win

  win.webContents.on 'crashed', ->
    global.logs.warning 'webContents crashed'
    setTimeout (-> win.reload()), 500

  win.webContents.on 'new-window', ->                      global.logs.debug 'webContents new-window'
  win.webContents.on 'will-navigate', ->                   global.logs.debug 'webContents will-navigate'
  win.webContents.on 'unresponsive', ->                    global.logs.debug 'webContents unresponsive'
  win.webContents.on 'responsive', ->                      global.logs.debug 'webContents responsive'
  win.webContents.on 'enter-html-full-screen', ->          global.logs.debug 'webContents enter-html-full-screen'
  win.webContents.on 'leave-html-full-screen', ->          global.logs.debug 'webContents leave-html-full-screen'
  win.webContents.on 'certificate-error', ->               global.logs.debug 'webContents certificate-error'
  win.webContents.on 'select-client-certificate', ->       global.logs.debug 'webContents select-client-certificate'
  win.webContents.on 'login', ->                           global.logs.debug 'webContents login'
  win.webContents.on 'remote-require', ->                  global.logs.debug 'webContents remote-require'
  win.webContents.on 'remote-get-global', ->               global.logs.debug 'webContents remote-get-global'
  win.webContents.on 'remote-get-builtin', ->              global.logs.debug 'webContents remote-get-builtin'
  win.webContents.on 'remote-get-current-window', ->       global.logs.debug 'webContents remote-get-current-window'
  win.webContents.on 'did-fail-load', ->                   global.logs.debug 'webContents did-fail-load'
  win.webContents.on 'did-fail-provisional-load', ->       global.logs.debug 'webContents did-fail-provisional-load'
  win.webContents.on 'will-redirect', ->                   global.logs.debug 'webContents will-redirect'
  win.webContents.on 'did-redirect-navigation', ->         global.logs.debug 'webContents did-redirect-navigation'
  win.webContents.on 'did-navigate-in-page', ->            global.logs.debug 'webContents did-navigate-in-page'
  win.webContents.on 'will-prevent-unload', ->             global.logs.debug 'webContents will-prevent-unload'
  win.webContents.on 'plugin-crashed', ->                  global.logs.debug 'webContents plugin-crashed'
  win.webContents.on 'destroyed', ->                       global.logs.debug 'webContents destroyed'
  win.webContents.on 'zoom-changed', ->                    global.logs.debug 'webContents zoom-changed'
  win.webContents.on 'found-in-page', ->                   global.logs.debug 'webContents found-in-page'
  win.webContents.on 'did-change-theme-color', ->          global.logs.debug 'webContents did-change-theme-color'
  win.webContents.on 'cursor-changed', ->                  global.logs.debug 'webContents cursor-changed'
  win.webContents.on 'context-menu', ->                    global.logs.debug 'webContents context-menu'
  win.webContents.on 'select-bluetooth-device', ->         global.logs.debug 'webContents select-bluetooth-device'
  win.webContents.on 'paint', ->                           global.logs.debug 'webContents paint'
  win.webContents.on 'will-attach-webview', ->             global.logs.debug 'webContents will-attach-webview'
  win.webContents.on 'did-attach-webview', ->              global.logs.debug 'webContents did-attach-webview'
  win.webContents.on 'console-message', ->                 global.logs.debug 'webContents console-message'
  win.webContents.on 'preload-error', ->                   global.logs.debug 'webContents preload-error'
  win.webContents.on 'ipc-message', ->                     global.logs.debug 'webContents ipc-message'
  win.webContents.on 'ipc-message-sync', ->                global.logs.debug 'webContents ipc-message-sync'
  win.webContents.on 'desktop-capturer-get-sources', ->    global.logs.debug 'webContents desktop-capturer-get-sources'
  win.webContents.on 'remote-get-current-web-contents', -> global.logs.debug 'webContents remote-get-current-web-contents'
  win.webContents.on 'remote-get-guest-web-contents', ->   global.logs.debug 'webContents remote-get-guest-web-contents'

  # Open the DevTools
  # win.webContents.openDevTools()

contextMenu(
  prepend: (defaultActions, params, browserWindow)->
    [
      { role: 'toggleFullScreen', label: 'Tela cheia' }
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
          global.versionsControl.exec(true)
      }
      {
        label: 'Reiniciar Equipamento',
        click: ->
          restartPlayer()
      }
      { type: 'separator' }
      {
        label: "Versão atual: #{global.versionsControl?.currentVersion || '--'}"
        enabled: false
      }
    ]
)

restartPlayer = ->
  global.logs.create 'Reiniciando Player!'
  return if ENV.NODE_ENV == 'development'

  shell.exec '/usr/bin/sudo reboot', (code, out, error)->
    global.logs.error "restartPlayer -> #{error}", tags: class: 'application' if error
  return

# Disable error dialogs by overriding
dialog.showErrorBox = (title, content)->
  global.logs.error "DIALOG -> #{title} #{content}"

app.setName 'SC Player'

app.on 'ready', createWindow
