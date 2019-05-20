# Publicidade

# Conexão SSH no Raspberry

Habilite o SSH nas configurações do Raspberry se não estiver habilitado.


`ssh pi@IP_DO_RASPBERRY`

# SSH sem senha

Execute `ssh-keygen` no seu PC.
Faça upload do id_rsa.pub para o Raspberry PI.

`scp id_rsa.pub pi@IP_DO_RASPBERRY:.ssh/authorized_keys`

# Montar imagem do Raspberry

Crie a pasta Raspberry no diretório /home/$USER

`mkdir /home/$USER/Raspberry/`

Agora é só executar o comando abaixo

`sshfs pi@IP_DO_RASPBERRY: /home/$USER/Raspberry/`

# Alterar a resolução do Raspbian

Edite o arquivo /boot/config.txt

```
# uncomment this if your display has a black border of unused pixels visible
# and your display can output without overscan
disable_overscan=1
```

```
# uncomment to force a console size. By default it will be display's size minus
# overscan.
framebuffer_width=1920
framebuffer_height=1080`
```

ou

`sudo raspi-config`

`Advanced Option` > `Resolution` > Selecione a resolução desejada

`reboot`
