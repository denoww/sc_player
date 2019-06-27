#!/bin/bash
xdotool mousemove 4000 4000
sleep 1
xdotool windowminimize $(xdotool getactivewindow)

cd ~/sc_player/
chromium-browser ~/sc_player/app/assets/templates/loading.html --noerrdialogs --kiosk --incognito --disable-translate &
npm start
