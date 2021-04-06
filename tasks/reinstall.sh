#!/bin/bash
cd /home/pi/sc_player/

sudo chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

rm -r node_modules
rm package-lock.json

_npm=$(which npm)
_npx=$(which npx)
$_npm install
$_npx electron-rebuild
