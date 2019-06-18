#!/bin/bash

# configurando variaveis de ambiente
echo '--- Configurando variáveis de ambiente'
read -p 'Informe o ID da TV: ' TV_ID
echo -e "TV_ID=$TV_ID\n" | sudo tee /etc/environment
source /etc/environment
sh -c 'cp ~/player_tv_raspberry/.env_DEVELOPMENT_sample ~/player_tv_raspberry/.env_DEVELOPMENT'

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

# sudo gedit /home/pi/.config/lxsession/LXDE-pi/autostart
# lxterminal -e bash /home/pi/inicio.sh

read -p 'Deseja Instalar xdotool para posisionar o MOUSE no canto da tela? (y/N) ' instalar_xdo
if [[ "$instalar_xdo" == "y" || "$instalar_xdo" == "Y" ]] ; then
  sh -c 'sudo apt install xdotool'
fi

read -p 'Deseja Executar o npm install? (y/N) ' executar_npm
if [[ "$executar_npm" == "y" || "$executar_npm" == "Y" ]] ; then
  sh -c 'npm install'
fi
