#!/bin/bash
cd /home/pi/sc_player/

/usr/bin/npm run delete_old_images
sleep 2

sudo chown pi:pi -R .
/usr/bin/git reset --hard
/usr/bin/git clean -f
/usr/bin/git pull

/usr/bin/npm install
sudo reboot
