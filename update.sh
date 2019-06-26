#!/bin/bash
cd /home/pi/sc_player/
git reset --hard
git clean -f
git pull
npm install
sudo reboot
