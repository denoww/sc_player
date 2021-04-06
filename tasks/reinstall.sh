#!/bin/bash
cd /home/pi/sc_player/

sudo chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

rm -r node_modules
rm package-lock.json

/usr/local/bin/npm install
/usr/local/bin/npx electron-rebuild
