#!/bin/bash

# atualizando tarefa_diaria
sudo cp /home/pi/sc_player/device_configs/tarefa_diaria /etc/cron.daily/
sudo chown root:root /etc/cron.daily/tarefa_diaria

# configurando wallpaper do dispositivo
cp /home/pi/sc_player/device_configs/wallpaper.png /home/pi/Pictures/
pcmanfm --set-wallpaper="/home/pi/Pictures/wallpaper.png"
