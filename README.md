# SC_Player

## Configurações iniciais

```
git clone https://github.com/denoww/sc_player.git
cd sc_player/
tasks/./config.sh
```

#### Alterar a "Autoplay policy" do Chromium

1. Abra o link: [chrome://flags/#autoplay-policy](chrome://flags/#autoplay-policy "chrome://flags/#autoplay-policy")
2. Altere a "Autoplay policy" para "No user gesture is required"
3. Clique em "Relaunch Now"
4. Reinicie o player

## Removendo libs desnecessárias

```
sudo apt-get remove --purge wolfram-engine scratch nuscratch sonic-pi idle3 smartsim java-common minecraft-pi python-minecraftpi python3-minecraftpi libreoffice python3-thonny geany claws-mail bluej greenfoot
sudo apt-get autoremove
```

## Desabilitar screensaver

Adicione o código abaixo no arquivo `/etc/xdg/lxsession/LXDE-pi/autostart`

```
@xset s noblank
@xset s off
@xset -dpms
```

Adicione o código abaixo no arquivo `/etc/lightdm/lightdm.conf`

```
xserver-command=X -s 0 dpms
```

## Conexão SSH no Raspberry

Habilite o SSH nas configurações do Raspberry se não estiver habilitado.

```
ssh pi@IP_DO_RASPBERRY
```

## SSH sem senha

Execute `ssh-keygen` no seu PC.
Faça upload do id_rsa.pub para o Raspberry PI.

```
scp ~/.ssh/id_rsa.pub pi@IP_DO_RASPBERRY:.ssh/authorized_keys
```

## Montar imagem do Raspberry

Crie a pasta Raspberry no diretório /home/$USER

```
mkdir /home/$USER/Raspberry/
```

Agora é só executar o comando abaixo

```
sshfs pi@IP_DO_RASPBERRY: /home/$USER/Raspberry/
```

## Alterar a resolução do Raspbian

Edite o arquivo `/boot/config.txt`

```
# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
disable_overscan=1
```

```
# uncomment to force a console size. By default it will be display's size minus
# overscan.
framebuffer_width=1920
framebuffer_height=1080
```

## Compilar arquivos .coffee do assets

```
coffee -wc app/assets/javascripts/*.coffee
```

## Corrigir erro 405 npm

```
npm config set registry https://registry.npmjs.org
sudo npm install -g npm
```
