# Index:

* [Prerequisites](#id10)
* [Docker-Compose con Vault](#id20)
  * [Creación del AppRole](#id21)
  * [Config cliente (docker-compose)](#id22)

# Prerequisites <div id='id10' />

Necesidades:

* Equipo con Vault desplegado (sin H.A.) en docker-compose
* Equipo cliente (S.O. pelado) con docker-compose

## Docker-Compose con Vault <div id='id20' /> 

### Creación del AppRole <div id='id21' />

```
root@vault:~# docker exec -it vault ash
```

```
/ # vault status
Key             Value
---             -----
...             ...
Sealed          false
...             ...

/ # export VAULT_ADDR=http://127.0.0.1:8200
/ # vault login s.KaU83zJXYPXaZZCfFkgT8eJX

/ # vault secrets enable -description="Secrets AppRole Docker Compose" -version=2 -path=docker-compose kv
/ # vault kv put docker-compose/vault-cli-docker/dbinfo username='secret-username' password='secret-password'

/ # vault policy write policy-vault-cli-docker - <<EOF
path "docker-compose/data/vault-cli-docker/dbinfo" {
    capabilities = ["read"]
}
EOF

/ # vault auth enable approle
/ # vault write auth/approle/role/vault-agent-role-docker-compose policies="policy-vault-cli-docker"

/ # vault read auth/approle/role/vault-agent-role-docker-compose/role-id
Key        Value
---        -----
role_id    3e3fab5c-f3b3-7489-9c42-6fa4e9ba73d4

/ # vault write -f auth/approle/role/vault-agent-role-docker-compose/secret-id
Key                   Value
---                   -----
secret_id             b0f8cf4c-a4e3-bd9a-3387-2fef649500df
secret_id_accessor    946ef901-791e-a362-e2ac-4069eeaed41e
secret_id_num_uses    0
secret_id_ttl         0s
```

The role_id and secret_id are required to authenticate via AppRole

### Config cliente (docker-compose) <div id='id22' />

```
root@vault-cli-docker:~# apt update && apt install -y unzip
root@vault-cli-docker:~# VAULT_RELEASE="1.19.4"
root@vault-cli-docker:~# wget https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip
root@vault-cli-docker:~# unzip vault_${VAULT_RELEASE}_linux_amd64.zip
root@vault-cli-docker:~# mv vault /usr/local/bin/
```

```
root@vault-cli-docker:~# vim /etc/docker-compose/vault-agent.hcl
vault {
  address = "http://vault.ilba.cat"
}
auto_auth {
   method "approle" {
       mount_path = "auth/approle"
       config = {
           role_id_file_path = "/etc/docker-compose/role_id"
           secret_id_file_path = "/etc/docker-compose/secret_id"
           remove_secret_id_file_after_reading = false
       }
   }
   sink "file" {
       config = {
           path = "/etc/docker-compose/vault-agent-token"
       }
   }
}
template {
  source      = "/etc/docker-compose/env-template.tmpl"
  destination = "/etc/docker-compose/.env"
}
```

```
root@vault-cli-docker:~# echo "3e3fab5c-f3b3-7489-9c42-6fa4e9ba73d4" > /etc/docker-compose/role_id
root@vault-cli-docker:~# echo "b0f8cf4c-a4e3-bd9a-3387-2fef649500df" > /etc/docker-compose/secret_id

root@vault-cli-docker:~# vim /etc/docker-compose/env-template.tmpl
DB_USER={{ with secret "docker-compose/data/vault-cli-docker/dbinfo" }}{{ .Data.data.username }}{{ end }}
DB_PASS={{ with secret "docker-compose/data/vault-cli-docker/dbinfo" }}{{ .Data.data.password }}{{ end }}

root@vault-cli-docker:~# vault agent -config=/etc/docker-compose/vault-agent.hcl

root@vault-cli-docker:~# cat /etc/docker-compose/.env
DB_USER=secret-username
DB_PASS=secret-password
```