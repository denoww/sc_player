#!/bin/bash

# criando pastas de downloads das midias
echo '--- Criando pastas de downloads das mídias'
sh -c 'mkdir ~/player_tv_raspberry/downloads'
sh -c 'mkdir ~/player_tv_raspberry/downloads/videos'
sh -c 'mkdir ~/player_tv_raspberry/downloads/images'
sh -c 'mkdir ~/player_tv_raspberry/downloads/audios'
sh -c 'mkdir ~/player_tv_raspberry/downloads/feeds'

# configurando barra de tarefas
echo '--- Configurando barra de tarefas'
sh -c 'cp ~/player_tv_raspberry/device_configs/panel /home/pi/.config/lxpanel/LXDE-pi/panels/panel'

# criando autostart
echo '--- Criando autostart'
sh -c 'mkdir /home/pi/.config/autostart'
sh -c 'cp ~/player_tv_raspberry/device_configs/player.desktop /home/pi/.config/autostart/'

# configurando wallpaper do dispo
echo '--- Configurando wallpaper do dispositivo'
sh -c 'cp ~/player_tv_raspberry/device_configs/wallpaper.png /home/pi/Pictures/'
sh -c 'pcmanfm --set-wallpaper="/home/pi/Pictures/wallpaper.png"'

# configurando variaveis de ambiente
read -p '--> Configurar variáveis de ambiente? (y/N) ' config_vars
if [[ "$config_vars" == "y" || "$config_vars" == "Y" ]] ; then
  read -p '--> Informe o ID da TV: ' TV_ID
  echo -e "TV_ID=$TV_ID\n" | sudo tee /etc/environment
  source /etc/environment
  sh -c 'cp ~/player_tv_raspberry/.env_DEVELOPMENT_sample ~/player_tv_raspberry/.env_DEVELOPMENT'
fi

read -p '--> Deseja Instalar xdotool para posisionar o MOUSE no canto da tela? (y/N) ' instalar_xdo
if [[ "$instalar_xdo" == "y" || "$instalar_xdo" == "Y" ]] ; then
  sh -c 'sudo apt install xdotool -y'
fi

read -p '--> Deseja Instalar nodejs? (y/N) ' instalar_node
if [[ "$instalar_node" == "y" || "$instalar_node" == "Y" ]] ; then
  sh -c 'sudo apt install nodejs -y'
fi

read -p '--> Deseja Instalar npm? (y/N) ' instalar_npm
if [[ "$instalar_npm" == "y" || "$instalar_npm" == "Y" ]] ; then
  sh -c 'sudo apt install npm -y'
fi

read -p '--> Deseja Executar o npm install? (y/N) ' executar_npm
if [[ "$executar_npm" == "y" || "$executar_npm" == "Y" ]] ; then
  sh -c 'npm install'
fi

read -p '--> Deseja Instalar notification-daemon? (y/N) ' instalar_notif
if [[ "$instalar_notif" == "y" || "$instalar_notif" == "Y" ]] ; then
  sh -c 'sudo apt install notification-daemon -y'
  echo '--- Criando org.freedesktop.Notifications'
  sh -c 'cp ~/player_tv_raspberry/device_configs/org.freedesktop.Notifications.service /usr/share/dbus-1/services/'
fi
