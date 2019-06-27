#!/bin/bash
chromium-browser ~/sc_player/app/assets/templates/loading.html --noerrdialogs --kiosk --incognito --disable-translate &

xdotool mousemove 4000 4000
xdotool windowminimize $(xdotool getactivewindow)

cd ~/sc_player/
npm run update_timezone &
npm start
