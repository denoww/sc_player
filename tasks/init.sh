#!/bin/bash
xdotool mousemove 4000 4000
sleep 1
xdotool windowminimize $(xdotool getactivewindow)

cd ~/sc_player/
npm start
