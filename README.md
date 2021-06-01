# SC_Player

## Configurações iniciais

```
git clone https://github.com/denoww/sc_player.git
cd sc_player/
tasks/./config.sh
```

## Removendo libs desnecessárias

```
sudo apt-get remove --purge wolfram-engine scratch nuscratch sonic-pi idle3 smartsim java-common minecraft-pi python-minecraftpi python3-minecraftpi libreoffice python3-thonny geany claws-mail bluej greenfoot
sudo apt-get autoremove
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

## Corrigir Timezone

```
sudo timedatectl set-timezone America/Sao_Paulo
```

--- OU ---

```
sudo dpkg-reconfigure tzdata
```

--- OU ---

```
sudo ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
ls -l /etc/localtime
```
