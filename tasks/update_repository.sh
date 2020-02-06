#!/bin/bash
cd /home/pi/sc_player/

sudo chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

/usr/bin/npm install

# reiniciar player
/home/pi/sc_player/tasks/./turn_off.sh
/home/pi/sc_player/tasks/./init.sh
