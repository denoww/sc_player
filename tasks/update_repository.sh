#!/bin/bash
cd /home/pi/sc_player/

sudo chown pi:pi -R .
git reset --hard
git clean -f
git pull

npm install
npx electron-rebuild
