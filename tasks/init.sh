#!/bin/bash
export DISPLAY=":0"
/usr/bin/xdotool mousemove 4000 4000

cd /home/pi/sc_player/
/usr/bin/git pull &
/usr/bin/npm run update_timezone &
/usr/bin/npm start
