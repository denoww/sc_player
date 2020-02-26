#!/bin/bash

cd /home/pi/sc_player/
rm -rf node_modules/sharp
npm install --ignore-scripts=false --unsafe-perm --arch=armv6 --platform=linux --target=10.15.0 sharp
/usr/bin/npx electron-rebuild
