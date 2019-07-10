{ app, BrowserWindow } = require 'electron'

createWindow = ->
  win = new BrowserWindow
    autoHideMenuBar: true
    useContentSize:  true
    backgroundColor: '#222'
    webPreferences:
      nodeIntegration: true
      webSecurity: false
  win.setFullScreen(true)

  win.loadURL 'http://localhost:3001'
  win.focus()
  global.win = win

  # Open the DevTools
  # win.webContents.openDevTools()

  win.on 'closed', ->
    win = null
  return

app.on 'ready', createWindow
global.app = app

process.on 'uncaughtException', (err)->
  global.logs.create("uncaughtException -> #{err}")
