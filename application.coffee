{ app, BrowserWindow } = require 'electron'

createWindow = ->
  win = new BrowserWindow
    autoHideMenuBar: true
    useContentSize: true
    webPreferences: nodeIntegration: true
  win.setFullScreen(true)

  win.loadURL 'http://localhost:3001'
  win.focus()

  # Open the DevTools
  # win.webContents.openDevTools()

  win.on 'closed', ->
    win = null
  return

app.on 'ready', createWindow
