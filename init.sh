#!/bin/bash
cd /home/pi/workspace/raspberry-video
nodemon --inspect server.coffee &
sleep 5
chromium-browser --app=http://127.0.0.1:3001 --start-fullscreen
