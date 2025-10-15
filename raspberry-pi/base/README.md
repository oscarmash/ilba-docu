* [Instalación base de RapsBerry Pi](#id10)
  * [Instalación en la microSD](#id11)
  * [Personalización del S.O.](#id12)
  * [SD Card to NVME](#id13)
  * [Configuración del S.O. + updates](#id14)
  * [Configuración del networking](#id15)
  * [neowofetch / neofetch](#id16)

# Instalación base de RapsBerry Pi <div id='id10' />

## Instalación en la microSD <div id='id11' />

Instalación de S.O. Debian en la microSD:

* Sistema Operrativo: Rapsberry Pi OS (other) -> Rapsberry Pi OS Lite (64-bit)
*  Personalización del S.O:
```
Nombre: 2025-05
General:
    Usuario: oscar.mas
    Password: sorisat
Ajustes regionales:
    Europe/Madrid
    es
Servicios:
    Activar SSH
```

## Personalización del S.O. <div id='id12' />

```
$ ssh-copy-id -i $HOME/.ssh/id_rsa.pub oscar.mas@172.26.0.111
$ ssh oscar.mas@172.26.0.111
```

```
oscar.mas@2025-05:~ $ sudo apt-get remove --purge -y ntp sntp systemd-timesyncd
oscar.mas@2025-05:~ $ sudo apt install -y postfix chrony iotop iputils-ping net-tools dnsutils curl telnet nmap gpg htop procps
```

```
oscar.mas@2025-05:~ $ sudo apt update && sudo apt install -y vim
oscar.mas@2025-05:~ $ echo "set mouse=c" > $HOME/.vimrc
oscar.mas@2025-05:~ $ echo "syntax on" >> $HOME/.vimrc
oscar.mas@2025-05:~ $ echo "set background=dark" >> $HOME/.vimrc
```

```
oscar.mas@2025-05:~ $ sudo rpi-eeprom-update
BOOTLOADER: up to date
   CURRENT: Thu  8 May 14:13:17 UTC 2025 (1746713597)
    LATEST: Thu  8 May 14:13:17 UTC 2025 (1746713597)
   RELEASE: default (/usr/lib/firmware/raspberrypi/bootloader-2712/default)
            Use raspi-config to change the release
```

## SD Card to NVME <div id='id13' />

Disabling Auto-Extension:

```
oscar.mas@2025-05:~ $ sudo sed -i 's| - growpart|# - growpart|' "/etc/cloud/cloud.cfg"
oscar.mas@2025-05:~ $ sudo sed -i 's| - resizefs|# - resizefs|' "/etc/cloud/cloud.cfg"
oscar.mas@2025-05:~ $ sudo touch /etc/growroot-disabled
```

```
oscar.mas@2025-05:~ $ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0         7:0    0     2G  0 loop
mmcblk0     179:0    0 119.1G  0 disk
├─mmcblk0p1 179:1    0   512M  0 part /boot/firmware
└─mmcblk0p2 179:2    0 118.6G  0 part /
zram0       254:0    0     2G  0 disk [SWAP]
nvme0n1     259:0    0 476.9G  0 disk
```

:warning: El siguiente paso tarda unos 25 minutos :warning:

```
oscar.mas@2025-05:~ $ sudo dd bs=4M if=/dev/mmcblk0 of=/dev/nvme0n1 status=progress oflag=sync
127808831488 bytes (128 GB, 119 GiB) copied, 1372 s, 93.2 MB/s
30485+1 records in
30485+1 records out
127865454592 bytes (128 GB, 119 GiB) copied, 1373 s, 93.1 MB/s
```

Change boot loader (Advanced Options -> Boot Order):

```
oscar.mas@2025-05:~ $ sudo raspi-config
```

Sacamos la tarjeta SD Card

## Configuración del S.O. + updates<div id='id14' />

```
oscar.mas@2025-05:~ $ sudo vim /etc/hosts
12.26.0.111     2025-05

oscar.mas@2025-05:~ $ sudo passwd root

oscar.mas@2025-05:~ $ sudo cat /etc/hostname
```

```
sudo apt update && \
sudo apt -y upgrade && \
sudo apt dist-upgrade -y && \
sudo apt -y autoremove --purge && \
sudo apt autoclean && \
sudo apt clean && \
sudo reboot
```

## Configuración del networking <div id='id15' />

```
oscar.mas@2025-05:~ $ sudo bash
root@2025-05:/home/oscar.mas# systemctl disable NetworkManager
root@2025-05:/home/oscar.mas# apt install -y ifupdown2
```

```
$ cat <<EOF > /etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
      address 172.26.0.111/24
      gateway 172.26.0.1
EOF
```

```
$ cat <<EOF > /etc/resolv.conf
search ilba.cat
nameserver 8.8.8.8
EOF
```

```
root@2025-05:/home/oscar.mas# reboot
```

## neowofetch / neofetch <div id='id16' />

Desde mi equipo local copiaremos el fichero de configuración a la Raspberry Pi

```
$ cd $HOME/ilba/ilba-docu/raspberry-pi/base/
$ scp files/neofetch.conf oscar.mas@172.26.0.111:
```

Desde la Raspberry Pi:

```
sudo apt-get update && sudo apt-get install -y neowofetch
sudo rm -rf /etc/update-motd.d/*

sudo chown root:root /home/oscar.mas/neofetch.conf
sudo chmod 0755 /home/oscar.mas/neofetch.conf
sudo mv /home/oscar.mas/neofetch.conf /etc/ssh/neofetch.conf

sudo vim /etc/ssh/sshd_config
    PrintMotd no
    PrintLastLog no
    Banner /dev/null

touch ~/.hushlogin    
sudo grep -c "^neofetch --config /etc/ssh/neofetch.conf" /etc/profile | true
sudo vim /etc/profile
    neowofetch --config /etc/ssh/neofetch.conf
sudo rm -rf /etc/motd
sudo raspi-config nonint do_wifi_country ES
sudo reboot
```