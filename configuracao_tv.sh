#!/bin/bash

# configurando variaveis de ambiente
CLIENTE_ID=46
TV_ID=3
echo -e "CLIENTE_ID=$CLIENTE_ID\nTV_ID=$TV_ID\n" > /etc/environment
source /etc/environment

# configurando barra de tarefas
cp device_configs/panel /home/$USER/.config/lxpanel/LXDE-pi/panels/panel

# criando autostart
cd /home/pi/.config/
mkdir autostart
cp device_configs/player.desktop /home/$USER/.config/autostart/

# configurando wallpaper do dispositivo
cp device_configs/wallpaper.png /home/$USER/Pictures/
PIC="/home/$USER/Pictures/wallpaper.png"
gsettings set org.gnome.desktop.background picture-uri "file://$PIC"

# sudo gedit /home/pi/.config/lxsession/LXDE-pi/autostart
# lxterminal -e bash /home/pi/inicio.sh

# disable display lock
gsettings set org.gnome.desktop.screensaver lock-enabled false


# Desabilitando proteção de tela

# Maiores informações em: http://raspberrypi.stackexchange.com/questions/752/how-do-i-prevent-the-screen-from-going-blank

# Instale o pacote xset

# apt-get install x11-xserver-utils

# Abra ou crie o arquivo ~/.xinitrc e adicione o seguinte conteúdo

# xset s off # don't activate screensaver
# xset -dpms # disable DPMS (Energy Star) features.
# xset s noblank # don't blank the video device
# exec /etc/alternatives/x-session-manager # start lxde
