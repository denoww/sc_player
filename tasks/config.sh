#!/bin/bash

# configurar desktop
read -p '--> Configurar Desktop? (y/N) ' config_desktop
if [[ "$config_desktop" == "y" || "$config_desktop" == "Y" ]] ; then
  # criando pastas de downloads das midias
  echo '--- Criando pastas de downloads das mídias'
  sh -c 'mkdir ~/sc_player/downloads'
  sh -c 'mkdir ~/sc_player/downloads/videos'
  sh -c 'mkdir ~/sc_player/downloads/images'
  sh -c 'mkdir ~/sc_player/downloads/audios'
  sh -c 'mkdir ~/sc_player/downloads/feeds'

  # configurando barra de tarefas
  echo '--- Configurando barra de tarefas'
  sh -c 'cp ~/sc_player/device_configs/panel /home/pi/.config/lxpanel/LXDE-pi/panels/panel'

  # criando autostart
  # echo '--- Criando autostart'
  # sh -c 'mkdir /home/pi/.config/autostart'
  # sh -c 'cp ~/sc_player/device_configs/player.desktop /home/pi/.config/autostart/'

  # configurando wallpaper do dispo
  echo '--- Configurando wallpaper do dispositivo'
  sh -c 'cp ~/sc_player/device_configs/wallpaper.png /home/pi/Pictures/'
  sh -c 'pcmanfm --set-wallpaper="/home/pi/Pictures/wallpaper.png"'
fi

# configurando variaveis de ambiente
read -p '--> Configurar variáveis de ambiente? (y/N) ' config_vars
if [[ "$config_vars" == "y" || "$config_vars" == "Y" ]] ; then
  read -p '--> Informe o ID da TV: ' TV_ID
  echo -e "TV_ID=$TV_ID\n" | sudo tee /etc/environment
  source /etc/environment
  sh -c 'cp ~/sc_player/.env_DEVELOPMENT_sample ~/sc_player/.env_DEVELOPMENT'
fi

# configurando variaveis de ambiente
read -p '--> Configurar Reinício Automático diário? (y/N) ' cron
if [[ "$cron" == "y" || "$cron" == "Y" ]] ; then
  sh -c 'sudo cp ~/sc_player/device_configs/tarefa_diaria /etc/cron.daily/'
  sh -c 'sudo chown root:root /etc/cron.daily/tarefa_diaria'
fi

read -p '--> Alterar logo da tela de abertura? (y/N) ' logo
if [[ "$logo" == "y" || "$logo" == "Y" ]] ; then
  # copia a logo para a pasta
  sh -c 'sudo cp ~/sc_player/device_configs/splash.png /usr/share/plymouth/themes/pix/'

  # adiciona 'logo.nologo' no /boot/cmdline.txt para remover a logo do raspberry
  TEM_LOGO=$(grep -rnw /boot/cmdline.txt -e 'logo.nologo')
  if [[ $TEM_LOGO ]]; then
    echo '/boot/cmdline.txt já está atualizado!'
  else
    sh -c 'sudo sed -i "s/$/ logo.nologo/" /boot/cmdline.txt'
  fi
fi

read -p '--> Atualizar autostart LXDE-pi? (y/N) ' atualizar_lxde
if [[ "$atualizar_lxde" == "y" || "$atualizar_lxde" == "Y" ]] ; then
  sh -c 'sudo cp ~/sc_player/device_configs/lxde-autostart /etc/xdg/lxsession/LXDE-pi/autostart'
fi

read -p '--> Instalar xdotool para posisionar o MOUSE no canto da tela? (y/N) ' instalar_xdo
if [[ "$instalar_xdo" == "y" || "$instalar_xdo" == "Y" ]] ; then
  sh -c 'sudo apt install xdotool -y'
fi

read -p '--> Instalar Firefox? (y/N) ' instalar_firefox
if [[ "$instalar_firefox" == "y" || "$instalar_firefox" == "Y" ]] ; then
  sh -c 'sudo apt install firefox-esr -y'
fi

read -p '--> Instalar nodejs? (y/N) ' instalar_node
if [[ "$instalar_node" == "y" || "$instalar_node" == "Y" ]] ; then
  sh -c 'sudo apt install nodejs -y'
fi

read -p '--> Instalar npm? (y/N) ' instalar_npm
if [[ "$instalar_npm" == "y" || "$instalar_npm" == "Y" ]] ; then
  sh -c 'sudo apt install npm -y'
fi

read -p '--> Executar o npm install? (y/N) ' executar_npm
if [[ "$executar_npm" == "y" || "$executar_npm" == "Y" ]] ; then
  sh -c 'npm install'
fi

read -p '--> Instalar notification-daemon? (y/N) ' instalar_notif
if [[ "$instalar_notif" == "y" || "$instalar_notif" == "Y" ]] ; then
  sh -c 'sudo apt install notification-daemon -y'
  echo '--- Criando org.freedesktop.Notifications'
  sh -c 'sudo cp ~/sc_player/device_configs/org.freedesktop.Notifications.service /usr/share/dbus-1/services/'
fi

read -p '--> Iniciar o servidor? (y/N) ' instalar_server
if [[ "$instalar_server" == "y" || "$instalar_server" == "Y" ]] ; then
  sh -c 'npm run start'
fi
