#!/bin/bash
cd /home/pi/sc_player/

npm run delete_old_images
sleep 2

git reset --hard
git clean -f
git pull

npm install
sudo reboot
