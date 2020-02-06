#!/bin/bash

# aumentando tamanho da memoria swap
echo -e "CONF_SWAPSIZE=1024" | /usr/bin/sudo tee /etc/dphys-swapfile
/usr/bin/sudo /etc/init.d/dphys-swapfile restart

# configurando crontab para reiniciar de o player desligar
/usr/bin/sudo cp /home/pi/sc_player/device_configs/crontab-sc-player /etc/cron.d/
/usr/bin/sudo chown root:root /etc/cron.d/crontab-sc-player

# removendo inicio automatico pelo lxde (cron vai iniciar o player)
/usr/bin/sudo cp /home/pi/sc_player/device_configs/lxde-autostart /etc/xdg/lxsession/LXDE-pi/autostart
