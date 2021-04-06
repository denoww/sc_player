#!/bin/bash
cd /home/pi/sc_player/

sudo chown pi:pi -R .
git reset --hard
git clean -f
git pull

rm -r node_modules
rm package-lock.json

npm install
npx electron-rebuild
