#!/bin/bash

# configurando variaveis de ambiente
echo '--- Configurando variáveis de ambiente'
read -p 'Informe o ID do Cliente: ' CLIENTE_ID
read -p 'Informe o ID da TV: ' TV_ID
echo -e "CLIENTE_ID=$CLIENTE_ID\nTV_ID=$TV_ID\n" | sudo tee /etc/environment
source /etc/environment
sh -c 'cp ~/workspace/player_tv_raspberry/.env_DEVELOPMENT_sample ~/workspace/player_tv_raspberry/.env_DEVELOPMENT'

# configurando barra de tarefas
echo '--- Configurando barra de tarefas'
sh -c 'cp ~/workspace/player_tv_raspberry/device_configs/panel /home/pi/.config/lxpanel/LXDE-pi/panels/panel'

# criando autostart
echo '--- Criando autostart'
sh -c 'mkdir /home/pi/.config/autostart'
sh -c 'cp ~/workspace/player_tv_raspberry/device_configs/player.desktop /home/pi/.config/autostart/'

# configurando wallpaper do dispo
echo '--- Configurando wallpaper do dispositivo'
sh -c 'cp ~/workspace/player_tv_raspberry/device_configs/wallpaper.png /home/pi/Pictures/'
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
