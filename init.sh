#!/bin/bash
# sudo nodemon --inspect /home/pi/workspace/player_tv_raspberry/server.coffee &
xdotool mousemove 4000 4000
cd /home/pi/workspace/player_tv_raspberry/
sudo npm start &
sleep 8
chromium-browser --app=http://127.0.0.1:3001 --start-fullscreen
