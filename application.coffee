# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, BrowserWindow } = require 'electron'
contextMenu = require 'electron-context-menu'

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

  win.on 'close', (e, c)->       global.logs.create('--- WIN --- close ->', e, c)
  win.on 'closed', (e, c)->      global.logs.create('--- WIN --- closed ->', e, c)
  win.on 'session-end', (e, c)-> global.logs.create('--- WIN --- session-end ->', e, c)
  win.on 'hide', (e, c)->        global.logs.create('--- WIN --- hide ->', e, c)

  win.webContents.on 'crashed', (e, c)->
    obj = JSON.stringify(e)
    global.logs.create('--- WEBCONTENTS --- crashed ->', obj, c)
    global.logs.create('--- RELOADING.........')
    win.reload()

  win.webContents.on 'page-title-updated', (e, c)-> global.logs.create('--- WEBCONTENTS --- page-title-updated ->', e, c)
  win.webContents.on 'new-window', (e, c)-> global.logs.create('--- WEBCONTENTS --- new-window ->', e, c)
  win.webContents.on 'will-navigate', (e, c)-> global.logs.create('--- WEBCONTENTS --- will-navigate ->', e, c)
  win.webContents.on 'unresponsive', (e, c)-> global.logs.create('--- WEBCONTENTS --- unresponsive ->', e, c)
  win.webContents.on 'responsive', (e, c)-> global.logs.create('--- WEBCONTENTS --- responsive ->', e, c)
  win.webContents.on 'enter-html-full-screen', (e, c)-> global.logs.create('--- WEBCONTENTS --- enter-html-full-screen ->', e, c)
  win.webContents.on 'leave-html-full-screen', (e, c)-> global.logs.create('--- WEBCONTENTS --- leave-html-full-screen ->', e, c)
  win.webContents.on 'certificate-error', (e, c)-> global.logs.create('--- WEBCONTENTS --- certificate-error ->', e, c)
  win.webContents.on 'select-client-certificate', (e, c)-> global.logs.create('--- WEBCONTENTS --- select-client-certificate ->', e, c)
  win.webContents.on 'login', (e, c)-> global.logs.create('--- WEBCONTENTS --- login ->', e, c)
  win.webContents.on 'remote-require', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-require ->', e, c)
  win.webContents.on 'remote-get-global', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-get-global ->', e, c)
  win.webContents.on 'remote-get-builtin', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-get-builtin ->', e, c)
  win.webContents.on 'remote-get-current-window', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-get-current-window ->', e, c)
  win.webContents.on 'did-finish-load', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-finish-load ->', e, c)
  win.webContents.on 'did-fail-load', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-fail-load ->', e, c)
  win.webContents.on 'did-frame-finish-load', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-frame-finish-load ->', e, c)
  win.webContents.on 'did-start-loading', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-start-loading ->', e, c)
  win.webContents.on 'did-stop-loading', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-stop-loading ->', e, c)
  win.webContents.on 'dom-ready', (e, c)-> global.logs.create('--- WEBCONTENTS --- dom-ready ->', e, c)
  win.webContents.on 'did-start-navigation', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-start-navigation ->', e, c)
  win.webContents.on 'will-redirect', (e, c)-> global.logs.create('--- WEBCONTENTS --- will-redirect ->', e, c)
  win.webContents.on 'did-redirect-navigation', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-redirect-navigation ->', e, c)
  win.webContents.on 'did-navigate', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-navigate ->', e, c)
  win.webContents.on 'did-frame-navigate', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-frame-navigate ->', e, c)
  win.webContents.on 'did-navigate-in-page', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-navigate-in-page ->', e, c)
  win.webContents.on 'will-prevent-unload', (e, c)-> global.logs.create('--- WEBCONTENTS --- will-prevent-unload ->', e, c)
  win.webContents.on 'plugin-crashed', (e, c)-> global.logs.create('--- WEBCONTENTS --- plugin-crashed ->', e, c)
  win.webContents.on 'destroyed', (e, c)-> global.logs.create('--- WEBCONTENTS --- destroyed ->', e, c)
  win.webContents.on 'before-input-event', (e, c)-> global.logs.create('--- WEBCONTENTS --- before-input-event ->', e, c)
  win.webContents.on 'devtools-opened', (e, c)-> global.logs.create('--- WEBCONTENTS --- devtools-opened ->', e, c)
  win.webContents.on 'devtools-closed', (e, c)-> global.logs.create('--- WEBCONTENTS --- devtools-closed ->', e, c)
  win.webContents.on 'devtools-focused', (e, c)-> global.logs.create('--- WEBCONTENTS --- devtools-focused ->', e, c)
  win.webContents.on 'found-in-page', (e, c)-> global.logs.create('--- WEBCONTENTS --- found-in-page ->', e, c)
  win.webContents.on 'media-started-playing', (e, c)-> global.logs.create('--- WEBCONTENTS --- media-started-playing ->', e, c)
  win.webContents.on 'media-paused', (e, c)-> global.logs.create('--- WEBCONTENTS --- media-paused ->', e, c)
  win.webContents.on 'did-change-theme-color', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-change-theme-color ->', e, c)
  win.webContents.on 'update-target-url', (e, c)-> global.logs.create('--- WEBCONTENTS --- update-target-url ->', e, c)
  win.webContents.on 'cursor-changed', (e, c)-> global.logs.create('--- WEBCONTENTS --- cursor-changed ->', e, c)
  win.webContents.on 'context-menu', (e, c)-> global.logs.create('--- WEBCONTENTS --- context-menu ->', e, c)
  win.webContents.on 'select-bluetooth-device', (e, c)-> global.logs.create('--- WEBCONTENTS --- select-bluetooth-device ->', e, c)
  win.webContents.on 'paint', (e, c)-> global.logs.create('--- WEBCONTENTS --- paint ->', e, c)
  win.webContents.on 'devtools-reload-page', (e, c)-> global.logs.create('--- WEBCONTENTS --- devtools-reload-page ->', e, c)
  win.webContents.on 'will-attach-webview', (e, c)-> global.logs.create('--- WEBCONTENTS --- will-attach-webview ->', e, c)
  win.webContents.on 'did-attach-webview', (e, c)-> global.logs.create('--- WEBCONTENTS --- did-attach-webview ->', e, c)
  win.webContents.on 'console-message', (e, c)-> global.logs.create('--- WEBCONTENTS --- console-message ->', e, c)
  win.webContents.on 'preload-error', (e, c)-> global.logs.create('--- WEBCONTENTS --- preload-error ->', e, c)
  win.webContents.on 'ipc-message', (e, c)-> global.logs.create('--- WEBCONTENTS --- ipc-message ->', e, c)
  win.webContents.on 'ipc-message-sync', (e, c)-> global.logs.create('--- WEBCONTENTS --- ipc-message-sync ->', e, c)
  win.webContents.on 'desktop-capturer-get-sources', (e, c)-> global.logs.create('--- WEBCONTENTS --- desktop-capturer-get-sources ->', e, c)
  win.webContents.on 'remote-get-current-web-contents', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-get-current-web-contents ->', e, c)
  win.webContents.on 'remote-get-guest-web-contents', (e, c)-> global.logs.create('--- WEBCONTENTS --- remote-get-guest-web-contents ->', e, c)

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

app.on 'will-finish-launching', (e)->     global.logs.create('--- ELECTRON --- will-finish-launching ->', e)
app.on 'window-all-closed', (e)->         global.logs.create('--- ELECTRON --- window-all-closed ->', e)
app.on 'before-quit', (e)->               global.logs.create('--- ELECTRON --- before-quit ->', e)
app.on 'will-quit', (e)->                 global.logs.create('--- ELECTRON --- will-quit ->', e)
app.on 'quit', (e)->                      global.logs.create('--- ELECTRON --- quit ->', e)
app.on 'web-contents-created', (e)->      global.logs.create('--- ELECTRON --- web-contents-created ->', e)
app.on 'certificate-error', (e)->         global.logs.create('--- ELECTRON --- certificate-error ->', e)
app.on 'login', (e)->                     global.logs.create('--- ELECTRON --- login ->', e)
app.on 'gpu-process-crashed', (e)->       global.logs.create('--- ELECTRON --- gpu-process-crashed ->', e)
app.on 'session-created', (e)->           global.logs.create('--- ELECTRON --- session-created ->', e)
app.on 'second-instance', (e)->           global.logs.create('--- ELECTRON --- second-instance ->', e)

process.on 'uncaughtException', (err)->  global.logs.create('--- NODE --- uncaughtException ->', err)
