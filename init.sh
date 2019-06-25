#!/bin/bash
# sudo nodemon --inspect /home/pi/sc_player/server.coffee &
xdotool mousemove 4000 4000
cd /home/pi/sc_player/
npm run start
# sudo npm run start &
# sleep 8
# chromium-browser --app=http://127.0.0.1:3001 --start-fullscreen
