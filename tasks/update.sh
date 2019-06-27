#!/bin/bash
cd /home/pi/sc_player/

npm run delete-old-images
sleep 5

git reset --hard
git clean -f
git pull

npm install
sudo reboot
