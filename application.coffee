# handle setupevents as quickly as possible
setupEvents = require './installers/setupEvents'
if setupEvents.handleSquirrelEvent()
  # squirrel event handled and app will exit in 1000ms, so don't do anything else
  return

{ app, dialog, protocol, BrowserWindow } = require 'electron'
contextMenu = require 'electron-context-menu'

createWindow = ->
  windowOptions =
    show:            false
    icon:            "#{__dirname}/app/assets/images/icon.png"
    kiosk:           true
    minWidth:        640
    minHeight:       360
    darkTheme:       true
    alwaysOnTop:     true
    autoplayPolicy:  'no-user-gesture-required'
    useContentSize:  true
    autoHideMenuBar: true
    backgroundColor: '#222'
    webPreferences:
      # webSecurity:     false
      nodeIntegration: true

  if ENV.NODE_ENV == 'development'
    windowOptions.kiosk       = false
    windowOptions.width       = 640
    windowOptions.height      = 360
    windowOptions.alwaysOnTop = true

  logs.info "Iniciando janela do Electron!"
  win = new BrowserWindow windowOptions

  win.loadURL 'http://localhost:3001'
  win.focus()
  win.once 'ready-to-show', -> win.show()

  # criando protoco seguro para carregar arquivos locais
  protocolName = 'sc-protocol'
  protocol.registerFileProtocol protocolName, (request, callback)->
    url = request.url.replace("#{protocolName}://", '')
    try
      return callback(decodeURIComponent(url))
    catch error
      logs.error(error)

  # atualizar a tela a cada 3 horas para limpar o cache
  setInterval ->
    logs.create 'Electron -> Atualização preventiva (3h)!'
    win.reload()
  , 1000 * 60 * 60 * 3 # 3 horas

  win.webContents.on 'crashed', ->
    logs.warning 'webContents crashed'
    setTimeout (-> win.reload()), 500

  win.webContents.on 'did-fail-load', ->
    logs.warning 'webContents did-fail-load'
    setTimeout (-> win.reload()), 1000

  win.webContents.on 'new-window', ->                      logs.debug 'webContents new-window'
  win.webContents.on 'will-navigate', ->                   logs.debug 'webContents will-navigate'
  win.webContents.on 'unresponsive', ->                    logs.debug 'webContents unresponsive'
  win.webContents.on 'responsive', ->                      logs.debug 'webContents responsive'
  win.webContents.on 'enter-html-full-screen', ->          logs.debug 'webContents enter-html-full-screen'
  win.webContents.on 'leave-html-full-screen', ->          logs.debug 'webContents leave-html-full-screen'
  win.webContents.on 'certificate-error', ->               logs.debug 'webContents certificate-error'
  win.webContents.on 'select-client-certificate', ->       logs.debug 'webContents select-client-certificate'
  win.webContents.on 'login', ->                           logs.debug 'webContents login'
  win.webContents.on 'remote-require', ->                  logs.debug 'webContents remote-require'
  win.webContents.on 'remote-get-global', ->               logs.debug 'webContents remote-get-global'
  win.webContents.on 'remote-get-builtin', ->              logs.debug 'webContents remote-get-builtin'
  win.webContents.on 'remote-get-current-window', ->       logs.debug 'webContents remote-get-current-window'
  win.webContents.on 'did-fail-provisional-load', ->       logs.debug 'webContents did-fail-provisional-load'
  win.webContents.on 'will-redirect', ->                   logs.debug 'webContents will-redirect'
  win.webContents.on 'did-redirect-navigation', ->         logs.debug 'webContents did-redirect-navigation'
  win.webContents.on 'did-navigate-in-page', ->            logs.debug 'webContents did-navigate-in-page'
  win.webContents.on 'will-prevent-unload', ->             logs.debug 'webContents will-prevent-unload'
  win.webContents.on 'plugin-crashed', ->                  logs.debug 'webContents plugin-crashed'
  win.webContents.on 'destroyed', ->                       logs.debug 'webContents destroyed'
  win.webContents.on 'zoom-changed', ->                    logs.debug 'webContents zoom-changed'
  win.webContents.on 'found-in-page', ->                   logs.debug 'webContents found-in-page'
  win.webContents.on 'did-change-theme-color', ->          logs.debug 'webContents did-change-theme-color'
  win.webContents.on 'cursor-changed', ->                  logs.debug 'webContents cursor-changed'
  win.webContents.on 'context-menu', ->                    logs.debug 'webContents context-menu'
  win.webContents.on 'select-bluetooth-device', ->         logs.debug 'webContents select-bluetooth-device'
  win.webContents.on 'paint', ->                           logs.debug 'webContents paint'
  win.webContents.on 'will-attach-webview', ->             logs.debug 'webContents will-attach-webview'
  win.webContents.on 'did-attach-webview', ->              logs.debug 'webContents did-attach-webview'
  win.webContents.on 'preload-error', ->                   logs.debug 'webContents preload-error'
  win.webContents.on 'ipc-message', ->                     logs.debug 'webContents ipc-message'
  win.webContents.on 'ipc-message-sync', ->                logs.debug 'webContents ipc-message-sync'
  win.webContents.on 'desktop-capturer-get-sources', ->    logs.debug 'webContents desktop-capturer-get-sources'
  win.webContents.on 'remote-get-current-web-contents', -> logs.debug 'webContents remote-get-current-web-contents'
  win.webContents.on 'remote-get-guest-web-contents', ->   logs.debug 'webContents remote-get-guest-web-contents'
  win.webContents.on 'did-finish-load', ->                 logs.debug 'webContents remote-get-guest-web-contents'

  win.onerror = (error, url, lineNumber)->
    logs.error "Error: #{error} Script: #{url} Line: #{lineNumber}"

  # Open the DevTools
  # win.webContents.openDevTools()

# definindo o nome do app
app.setName 'SC Player'

# criar janela quando estiver pronto
app.whenReady().then ->
  createWindow()

# criar janela quando for ativado e nao existir nenhuma
app.on 'activate', ->
  createWindow() unless BrowserWindow.getAllWindows().length

# encerrar o app se não existir nenhuma janela aberta
app.on 'window-all-closed', -> app.quit()

# opcoes do menu do botão direito do mouse no app
contextMenu prepend: (defaultActions, params, browserWindow)->
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
    # {
    #   label: 'Atualizar Equipamento',
    #   click: ->
    #     versionsControl.exec(true)
    # }
    {
      label: 'Reiniciar Equipamento',
      click: ->
        restartDevice()
    }
    # { type: 'separator' }
    # {
    #   label: "Versão atual: #{versionsControl?.currentVersion || '--'}"
    #   enabled: false
    # }
  ]

# reiniciar equipamento
restartDevice = ->
  logs.create 'Reiniciando Player!'
  return if ENV.NODE_ENV == 'development'

  shell = require 'shelljs'
  shell.exec 'sudo /sbin/reboot', (code, out, error)->
    logs.error "restartDevice -> #{error}", tags: class: 'application' if error
  return

# Disable error dialogs by overriding
dialog.showErrorBox = (title, content)->
  logs.error "DIALOG -> #{title} #{content}"
