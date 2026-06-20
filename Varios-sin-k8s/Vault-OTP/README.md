# Index:

* [Prerequisites](#id10)
* [Configuración de Vault](#id20)
* [Configuración del cliente](#id30)

# Prerequisites <div id='id10' />

En este lab usaremos dos equipos:
* Vault     172.26.0.30 (vault)
* Cliente   172.26.0.240 (client-otp-vault)

# Configuración de Vault <div id='id20' />

```
root@vault:~# docker exec -it vault ash
/ # export VAULT_ADDR=http://127.0.0.1:8200
/ # vault login s.KaU83zJXYPXaZZCfFkgT8eJX
```

```
/ # vault secrets enable -path=otp_ssh -description="Motor SSH para contraseñas de un solo uso (OTP)" ssh

/ # vault secrets list
Path          Type         Accessor              Description
----          ----         --------              -----------
cubbyhole/    cubbyhole    cubbyhole_56ed61f9    per-token private secret storage
identity/     identity     identity_53938dc5     identity store
otp_ssh/      ssh          ssh_68e013df          Motor SSH para contraseñas de un solo uso (OTP)
sys/          system       system_6e42f7a1       system endpoints used for control, policy and debugging
```

El parámetro "default_user=username" es el usuario que Vault asumirá por defecto si no le pasas uno al solicitar la clave.

```
/ # vault write otp_ssh/roles/otp_key_role \
key_type=otp \
default_user=username \
cidr_list=172.26.0.0/24 \
allowed_users="*"
```

```
/ # vault write otp_ssh/creds/otp_key_role ip=172.26.0.240 username=oscar.mas
Key                Value
---                -----
lease_id           otp_ssh/creds/otp_key_role/B5YaFNncHYiM4ujo15oAAddg
lease_duration     768h
lease_renewable    false
ip                 172.26.0.240
key                aacedcc6-5281-8eb1-869f-f0a5b66c4bab
key_type           otp
port               22
username           oscar.mas
```

El password para poder acceder por ssh es: aacedcc6-5281-8eb1-869f-f0a5b66c4bab

# Configuración del cliente <div id='id30' />

```
root@client-otp-vault:~# vim /etc/ssh/sshd_config
# Habilita la autenticación por teclado interactivo (necesaria para PAM)
KbdInteractiveAuthentication yes
# Asegura que SSH use el sistema PAM del sistema operativo
UsePAM yes
# Deshabilita el login directo por contraseña estándar (opcional, por seguridad)
PasswordAuthentication no

root@client-otp-vault:~# systemctl restart ssh
```

```
root@client-otp-vault:~# vim /etc/pam.d/vault-otp
# /etc/pam.d/vault-otp
auth [success=done default=ignore] pam_exec.so quiet expose_authtok /usr/local/bin/vault-ssh-helper -config=/etc/vault-ssh-helper.d/config.hcl -dev
```

La siguiente línea hay que ponerla arriba del todo

```
root@client-otp-vault:~# vim /etc/pam.d/sshd
@include vault-otp
```

```
root@client-otp-vault:~# mkdir -p /etc/vault-ssh-helper.d
root@client-otp-vault:~# vim /etc/vault-ssh-helper.d/config.hcl
vault_addr = "http://172.26.0.30"
ssh_mount_point = "otp_ssh"
tls_skip_verify = true
allowed_roles = "*"
```

Ver la ultima release del helper: https://releases.hashicorp.com/vault-ssh-helper/

```
root@client-otp-vault:~# cd /tmp
root@client-otp-vault:/tmp# wget https://releases.hashicorp.com/vault-ssh-helper/0.2.4/vault-ssh-helper_0.2.4_linux_amd64.zip
root@client-otp-vault:/tmp# apt-get update && apt-get install -y unzip
root@client-otp-vault:/tmp# unzip vault-ssh-helper_0.2.4_linux_amd64.zip
root@client-otp-vault:/tmp# mv vault-ssh-helper /usr/local/bin/
root@client-otp-vault:/tmp# chmod +x /usr/local/bin/vault-ssh-helper
```

Verificaremos que todo funciona correctamente.

```
root@client-otp-vault:/tmp# vault-ssh-helper -verify-only -config=/etc/vault-ssh-helper.d/config.hcl -dev
2026-06-20T12:13:55.886+0200 [WARN]  Dev mode is enabled!
2026-06-20T12:13:55.887+0200 [INFO]  using SSH mount point: otp_ssh
2026-06-20T12:13:55.887+0200 [INFO]  using namespace:
2026-06-20T12:13:55.893+0200 [INFO]  vault-ssh-helper verification successful!
```

```
root@client-otp-vault:~# useradd -m -s /bin/bash oscar.mas
```

Veficaremos el acceso por ssh. 
Recordar que la contraseña, es la que nos ha dado antes: "aacedcc6-5281-8eb1-869f-f0a5b66c4bab" y que las OTPs se invalidan inmediatamente si se usan (aunque fallen) o si expira el tiempo.

```
$ ssh oscar.mas@172.26.0.240
```

```
root@client-otp-vault:~# journalctl -u ssh -f
Jun 20 12:27:01 client-otp-vault sshd-session[1105]: Accepted keyboard-interactive/pam for oscar.mas from 172.26.0.218 port 57506 ssh2
Jun 20 12:27:01 client-otp-vault sshd-session[1105]: pam_unix(sshd:session): session opened for user oscar.mas(uid=1001) by oscar.mas(uid=0)
```

NOTA: se pude hacer un login y veras como el segundo no funciona. Para poder hacer otro login, se le he de crear otro password desde Vault:

```
/ # vault write otp_ssh/creds/otp_key_role ip=172.26.0.240 username=oscar.mas
```

