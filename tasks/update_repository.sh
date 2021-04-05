#!/bin/bash
cd /home/pi/sc_player/

sudo /bin/chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

/bin/rm -r node_modules
/bin/rm package-lock.json

/usr/bin/npm install
/usr/bin/npx electron-rebuild
