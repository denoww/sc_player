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

  win.on 'close', (e, c)->                  global.logs.create('--- WIN --- close:', e, c)
  win.on 'closed', (e, c)->                 global.logs.create('--- WIN --- closed:', e, c)
  win.on 'session-end', (e, c)->            global.logs.create('--- WIN --- session-end:', e, c)
  win.on 'unresponsive', (e, c)->           global.logs.create('--- WIN --- unresponsive:', e, c)
  win.on 'responsive', (e, c)->             global.logs.create('--- WIN --- responsive:', e, c)
  win.on 'blur', (e, c)->                   global.logs.create('--- WIN --- blur:', e, c)
  win.on 'focus', (e, c)->                  global.logs.create('--- WIN --- focus:', e, c)
  win.on 'show', (e, c)->                   global.logs.create('--- WIN --- show:', e, c)
  win.on 'hide', (e, c)->                   global.logs.create('--- WIN --- hide:', e, c)
  win.on 'ready-to-show', (e, c)->          global.logs.create('--- WIN --- ready-to-show:', e, c)
  win.on 'maximize', (e, c)->               global.logs.create('--- WIN --- maximize:', e, c)
  win.on 'unmaximize', (e, c)->             global.logs.create('--- WIN --- unmaximize:', e, c)
  win.on 'minimize', (e, c)->               global.logs.create('--- WIN --- minimize:', e, c)
  win.on 'restore', (e, c)->                global.logs.create('--- WIN --- restore:', e, c)
  win.on 'resize', (e, c)->                 global.logs.create('--- WIN --- resize:', e, c)
  win.on 'move', (e, c)->                   global.logs.create('--- WIN --- move:', e, c)
  win.on 'enter-full-screen', (e, c)->      global.logs.create('--- WIN --- enter-full-screen:', e, c)
  win.on 'leave-full-screen', (e, c)->      global.logs.create('--- WIN --- leave-full-screen:', e, c)
  win.on 'enter-html-full-screen', (e, c)-> global.logs.create('--- WIN --- enter-html-full-screen:', e, c)
  win.on 'leave-html-full-screen', (e, c)-> global.logs.create('--- WIN --- leave-html-full-screen:', e, c)


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

app.on 'will-finish-launching', ->     global.logs.create("--- ELECTRON --- will-finish-launching!")
app.on 'ready', ->                     global.logs.create("--- ELECTRON --- ready!")
app.on 'window-all-closed', ->         global.logs.create("--- ELECTRON --- window-all-closed!")
app.on 'before-quit', ->               global.logs.create("--- ELECTRON --- before-quit!")
app.on 'will-quit', ->                 global.logs.create("--- ELECTRON --- will-quit!")
app.on 'quit', ->                      global.logs.create("--- ELECTRON --- quit!")
app.on 'browser-window-blur', ->       global.logs.create("--- ELECTRON --- browser-window-blur!")
app.on 'browser-window-focus', ->      global.logs.create("--- ELECTRON --- browser-window-focus!")
app.on 'browser-window-created', ->    global.logs.create("--- ELECTRON --- browser-window-created!")
app.on 'web-contents-created', ->      global.logs.create("--- ELECTRON --- web-contents-created!")
app.on 'certificate-error', ->         global.logs.create("--- ELECTRON --- certificate-error!")
app.on 'select-client-certificate', -> global.logs.create("--- ELECTRON --- select-client-certificate!")
app.on 'login', ->                     global.logs.create("--- ELECTRON --- login!")
app.on 'gpu-process-crashed', ->       global.logs.create("--- ELECTRON --- gpu-process-crashed!")
app.on 'session-created', ->           global.logs.create("--- ELECTRON --- session-created!")
app.on 'second-instance', ->           global.logs.create("--- ELECTRON --- second-instance!")
app.on 'remote-require', ->            global.logs.create("--- ELECTRON --- remote-require!")
app.on 'remote-get-global', ->         global.logs.create("--- ELECTRON --- remote-get-global!")
app.on 'remote-get-builtin', ->        global.logs.create("--- ELECTRON --- remote-get-builtin!")
app.on 'remote-get-current-window', -> global.logs.create("--- ELECTRON --- remote-get-current-window!")

process.on 'beforeExit', (err)->         global.logs.create('--- NODE --- beforeExit ->', err)
process.on 'disconnect', (err)->         global.logs.create('--- NODE --- disconnect ->', err)
process.on 'exit', (err)->               global.logs.create('--- NODE --- exit ->', err)
process.on 'message', (err)->            global.logs.create('--- NODE --- message ->', err)
process.on 'multipleResolves', (type, promise, reason)->   global.logs.create('--- NODE --- multipleResolves ->', type, promise, reason)
process.on 'rejectionHandled', (err)->   global.logs.create('--- NODE --- rejectionHandled ->', err)
process.on 'uncaughtException', (err)->  global.logs.create('--- NODE --- uncaughtException ->', err)
process.on 'unhandledRejection', (err)-> global.logs.create('--- NODE --- unhandledRejection ->', err)
process.on 'warning', (err)->            global.logs.create('--- NODE --- warning ->', err)

process.on 'SIGUSR1',  (err)-> global.logs.create('--- NODE --- SIGUSR1 ->', err)
process.on 'SIGTERM',  (err)-> global.logs.create('--- NODE --- SIGTERM ->', err)
process.on 'SIGPIPE',  (err)-> global.logs.create('--- NODE --- SIGPIPE ->', err)
process.on 'SIGHUP',   (err)-> global.logs.create('--- NODE --- SIGHUP ->', err)
process.on 'SIGTERM',  (err)-> global.logs.create('--- NODE --- SIGTERM ->', err)
process.on 'SIGINT',   (err)-> global.logs.create('--- NODE --- SIGINT ->', err)
process.on 'SIGBREAK', (err)-> global.logs.create('--- NODE --- SIGBREAK ->', err)
process.on 'SIGWINCH', (err)-> global.logs.create('--- NODE --- SIGWINCH ->', err)
process.on 'SIGKILL',  (err)-> global.logs.create('--- NODE --- SIGKILL ->', err)
process.on 'SIGSTOP',  (err)-> global.logs.create('--- NODE --- SIGSTOP ->', err)
process.on 'SIGBUS',   (err)-> global.logs.create('--- NODE --- SIGBUS ->', err)
