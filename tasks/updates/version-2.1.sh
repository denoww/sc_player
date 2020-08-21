#!/bin/bash
export DISPLAY=":0"

cd /home/pi/sc_player/
# alterando o wallpaper
sh -c 'cp device_configs/wallpaper.png /home/pi/Pictures/wallpaper.png'
sh -c 'pcmanfm --set-wallpaper="/home/pi/Pictures/wallpaper.png"'

# alterando a logo de inicializacao
sh -c 'sudo cp device_configs/splash.png /usr/share/plymouth/themes/pix/splash.png'

# adiciona 'logo.nologo' no /boot/cmdline.txt para remover a logo do raspberry
TEM_LOGO=$(grep -rnw /boot/cmdline.txt -e 'logo.nologo')
if [[ $TEM_LOGO ]]; then
  echo '/boot/cmdline.txt já está atualizado!'
else
  sh -c 'sudo sed -i "s/$/ logo.nologo/" /boot/cmdline.txt'
fi
