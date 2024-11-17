# Index:

* [Transit](#id10)
  * [Instalación vault en docker-compose](#id11)
  * [Unseal de Vault](#id12)

# Transit <div id='id10' />

Necesitamos un equipo con docker-compose, para poder desplegar el transit.

## Instalación vault en docker-compose <div id='id11' />

```
root@vault-transit:~# apt-get update && apt-get install -y jq
```

```
root@vault-transit:~# mkdir -p /etc/vault-server/{config,file}

root@vault-transit:~# cat <<EOF >> /etc/vault-server/config/vault.json
{
    "disable_mlock": true,
    "backend": {
      "file": {
        "path": "/vault/file"
      }
    },
    "listener": {
      "tcp":{
        "address": "0.0.0.0:8200",
        "tls_disable": 1
      }
    },
    "ui": true
}
EOF
```

```
root@vault-transit:~# mkdir -p /etc/nginx/conf.d/

root@vault-transit:~# vim /etc/nginx/conf.d/default.conf
upstream vault {
  server vault:8200 max_fails=3;
}
server {
  listen *:80;
  server_name _;
  location /healthz {
      stub_status;
  }
  location / {
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Host $host;
    proxy_set_header X-Forwarded-Server $host;
    proxy_set_header X-Forwarded-Port $server_port;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_pass http://vault;
  }
}
```


```
root@vault-transit:~# cat <<EOF >> /etc/docker-compose/docker-compose.yaml
version: '3'
services:
  nginx:
    container_name: 'nginx'
    hostname: 'nginx'
    image: 'nginx:1.25.3-alpine'
    depends_on:
      - 'vault'
    ports:
      - '80:80'
    volumes:
      - '/etc/localtime:/etc/localtime:ro'
      - '/etc/nginx/conf.d/default.conf:/etc/nginx/conf.d/default.conf'
  vault:
    container_name: vault
    hostname: vault
    image: hashicorp/vault:1.17.5
    restart: always
    environment:
      VAULT_ADDR: http://localhost:8200
    ports:
      - "8200:8200"
    cap_add:
      - 'IPC_LOCK'
    volumes:
      - /etc/vault-server/config/vault.json:/etc/vault-server/config/vault.json
      - /etc/vault-server/file:/vault/file
      - /etc/localtime:/etc/localtime:ro
    command: "vault server -config=/etc/vault-server/config/vault.json"
EOF

root@vault-transit:~# docker-compose -f /etc/docker-compose/docker-compose.yaml up -d

root@vault-transit:~# docker ps -a
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                                       NAMES
d8581e800825   nginx:1.25.3-alpine      "/docker-entrypoint.…"   7 seconds ago   Up 6 seconds   0.0.0.0:80->80/tcp, :::80->80/tcp           nginx
fcc757fc5331   hashicorp/vault:1.17.5   "docker-entrypoint.s…"   8 seconds ago   Up 7 seconds   0.0.0.0:8200->8200/tcp, :::8200->8200/tcp   vault
```

## Unseal de Vault <div id='id12' />

```
root@vault-transit:~# docker exec -it vault vault operator init
Unseal Key 1: Zj/Q2S61eJOWXCsc6Tfk0U0sT7ik5vZ5NG+FgNUujX0E
Unseal Key 2: TVfWLVB2AgYMuu8Zbsi9cKtEbaGRNGUW2G58lkpfmKPR
Unseal Key 3: 0asMZgvUs+i32TGTkw3/chljI4P+5xkOA+xuKcMqEIfq
Unseal Key 4: 0OUHexn7D1Td6IeLVHCZC/S+EPcv3v10Ztq5aDDh2O1k
Unseal Key 5: W8yy5i/N/xffXXjPl0s9//GucSTM/yEzXbMNeTDns2os

Initial Root Token: hvs.bbUzLpUPeshAAR6gCCrm5UjU
```

```
root@vault-transit:~# vim /usr/local/sbin/unsealt_vault_script.sh
#!/bin/bash

VAULT_ADDR='172.26.0.235'

KEY=(
     'Zj/Q2S61eJOWXCsc6Tfk0U0sT7ik5vZ5NG+FgNUujX0E'
     'TVfWLVB2AgYMuu8Zbsi9cKtEbaGRNGUW2G58lkpfmKPR'
     '0asMZgvUs+i32TGTkw3/chljI4P+5xkOA+xuKcMqEIfq'
    )

for i in "${KEY[@]}"; do
    echo "$i"
    curl -s --request PUT --data "{\"key\": \"$i\"}" $VAULT_ADDR/v1/sys/unseal
    sleep 5
done

SEALED=`curl -s $VAULT_ADDR/v1/sys/seal-status | jq '.sealed'`


if [[ $SEALED == "true" ]]
then
  echo "Vault is sealed: SHIT"
else
  echo "Vault is unsealed: OK"
fi


root@vault-transit:~# chmod +x /usr/local/sbin/unsealt_vault_script.sh
root@vault-transit:~# /usr/local/sbin/unsealt_vault_script.sh

root@vault-transit:~# docker exec -it vault vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.17.5
Build Date      2024-08-30T15:54:57Z
Storage Type    file
Cluster Name    vault-cluster-3ca45972
Cluster ID      dae6fc79-4abf-77eb-03a2-f20b240da24f
HA Enabled      false
```

```
root@vault-transit:~# cat <<EOF >> /etc/systemd/system/unsealt_vault_script.service
[Unit]
Description="Unseal Vault"
Wants=vault.service consul.service

[Service]
ExecStart=/usr/local/sbin/unsealt_vault_script.sh
ExecStartPre=/bin/sleep 30

[Install]
WantedBy=multi-user.target
EOF

root@vault-transit:~# systemctl daemon-reload && systemctl enable unsealt_vault_script.service && reboot
```

```
root@vault-transit:~# docker exec -it vault vault status
Key             Value
---             -----
Seal Type       shamir
Initialized     true
Sealed          false
Total Shares    5
Threshold       3
Version         1.17.5
Build Date      2024-08-30T15:54:57Z
Storage Type    file
Cluster Name    vault-cluster-3ca45972
Cluster ID      dae6fc79-4abf-77eb-03a2-f20b240da24f
HA Enabled      false
```

Verificamos el accceso via web:

* URL: http://172.26.0.235
* TOKEN: hvs.bbUzLpUPeshAAR6gCCrm5UjU

![alt text](images/transit-01-unseal.png)