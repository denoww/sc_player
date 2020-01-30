#!/bin/bash

# aumentando tamanho da memoria swap
echo -e "CONF_SWAPSIZE=1024" | sudo tee /etc/dphys-swapfile
sudo /etc/init.d/dphys-swapfile restart

# configurando crontab para reiniciar de o player desligar
sudo cp /home/pi/sc_player/device_configs/crontab-sc-player /etc/cron.d/
sudo chown root:root /etc/cron.d/crontab-sc-player

# removendo inicio automatico pelo lxde (cron vai iniciar o player)
sudo cp /home/pi/sc_player/device_configs/lxde-autostart /etc/xdg/lxsession/LXDE-pi/autostart
