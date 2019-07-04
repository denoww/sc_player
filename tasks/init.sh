#!/bin/bash
xdotool mousemove 4000 4000

cd ~/sc_player/
npm run update_timezone &
npm start
