#!/bin/sh
xdotool mousemove 4000 4000
sleep 2
xdotool windowminimize $(xdotool getactivewindow)

cd /home/pi/sc_player/
npm run start
