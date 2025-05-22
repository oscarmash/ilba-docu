# Index:

* [Prerequisites](#id10)
* [Ansible con Vault](#id20)
  * [Creación de secrets + usuario](#id21)
  * [Ansible secrets con Vault](#id22)
* [Change default TTL of Tokens](#id30)

# Prerequisites <div id='id10' />

Necesidades:

* Equipo con Vault desplegado (sin H.A.) en docker-compose
* Equipo cliente (S.O. pelado)

## Ansible con Vault <div id='id20' /> 

### Creación de secrets + usuario <div id='id21' />

```
root@vault:~# docker exec -it vault ash

/ # vault status
Key             Value
---             -----
...             ...
Sealed          false
...             ...

/ # export VAULT_ADDR=http://127.0.0.1:8200
/ # vault login s.KaU83zJXYPXaZZCfFkgT8eJX

/ # vault secrets enable -description="Secrets ansible DiBa" -version=2 -path=ansible kv
/ # vault kv put ansible/myapp/config username='secret-username' password='secret-password'

/ # vault kv get -format=json ansible/myapp/config
...
      "password": "secret-password",
      "username": "secret-username"
...

/ # vault policy write policy-myapp - <<EOF
path "ansible/data/myapp/config" {
    capabilities = ["read"]
}
EOF

/ # vault policy list
default
policy-myapp
root
```

```
/ # vault auth enable userpass
/ # vault write auth/userpass/users/oscar.mas password=superpassword policies=policy-myapp
/ # vault login -method=userpass username=oscar.mas password=superpassword

/ # vault kv get -format=json ansible/myapp/config
...
      "password": "secret-password",
      "username": "secret-username"
...

```

### Ansible secrets con Vault <div id='id22' />

Instalación del cliente de vault:

```
root@cli-ansible-vault:~# apt update && apt install -y ansible unzip python3-hvac
root@cli-ansible-vault:~# VAULT_RELEASE="1.19.4"
root@cli-ansible-vault:~# wget https://releases.hashicorp.com/vault/${VAULT_RELEASE}/vault_${VAULT_RELEASE}_linux_amd64.zip
root@cli-ansible-vault:~# unzip vault_${VAULT_RELEASE}_linux_amd64.zip
root@cli-ansible-vault:~# mv vault /usr/local/bin/
```

Verificamos que podemos acceder a Vault:

```
root@cli-ansible-vault:~# export VAULT_ADDR=http://172.26.0.30
root@cli-ansible-vault:~# vault login -method=userpass username=oscar.mas password=superpassword
```

Que sucede al hacer login:
* Nos da un token: hvs.xxx
* El token dura: 768h (The default Vault TTL is 32 days)

```
root@cli-ansible-vault:~# vault kv get -format=json ansible/myapp/config
      "password": "secret-password",
      "username": "secret-username"
```

Realizamos un ansible para recuperar datos de un Ansible.
Siempre hay que tener la variable *VAULT_TOKEN* definida

```
root@cli-ansible-vault:~# export VAULT_TOKEN="hvs.xxx"
```

Playbook de prueba

```
root@cli-ansible-vault:~# vim test-vault.yaml
---
- hosts: localhost
  gather_facts: false

  vars:
    ansible_hashi_vault_url: "http://172.26.0.30"
    ansible_hashi_vault_timeout: 5
    ansible_hashi_vault_retries: 3
    ansible_hashi_vault_auth_method: "token"

  tasks:
    - name: "HashiCorp Vault - Show username"
      debug:
        msg: "{{ lookup('community.hashi_vault.hashi_vault', 'ansible/data/myapp/config:username')}}"
    - name: "HashiCorp Vault - Show password"
      debug:
        msg: "{{ lookup('community.hashi_vault.hashi_vault', 'ansible/data/myapp/config:password')}}"

    - name: "HashiCorp Vault - Create file: /root/vault.secrets"
      copy:
        dest: "/root/vault.secrets"
        content: |
          Username: {{ lookup('community.hashi_vault.hashi_vault', 'ansible/data/myapp/config:username')}}
          Password: {{ lookup('community.hashi_vault.hashi_vault', 'ansible/data/myapp/config:password')}}
```

```
root@cli-ansible-vault:~# export VAULT_TOKEN="hvs.CAESIJmb6qXsYLywogIegjmg9k50uzYHtCgwT-eg3ZxaEBpLGh4KHGh2cy45TG9mU1JtSGtUUEl4MkpseGM2N3pia3c"

root@cli-ansible-vault:~# ansible-playbook test-vault.yaml
PLAY [localhost] ******************************************************

TASK [HashiCorp Vault - Show username] ********************************
ok: [localhost] => {
    "msg": "secret-username"
}

TASK [HashiCorp Vault - Show password] ********************************
ok: [localhost] => {
    "msg": "secret-password"
}

TASK [HashiCorp Vault - Create file: /root/vault.secrets] *************
changed: [localhost]

PLAY RECAP ************************************************************
localhost                  : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
```

```
root@cli-ansible-vault:~# cat vault.secrets
Username: secret-username
Password: secret-password
```

# Change default TTL of Tokens <div id='id30' />

Se puede cambiar el TTL en siguientes niveles:
* Vault server configuration file -> para todo el mundo
* The global maximum can be overridden on a per-auth-method basis
* A nivel de política

En este ejemplo lo haremos a nivel de auth con username/password:

```
root@cli-ansible-vault:~# export VAULT_ADDR=http://172.26.0.30
root@cli-ansible-vault:~# vault login s.KaU83zJXYPXaZZCfFkgT8eJX

root@cli-ansible-vault:~# vault read sys/auth/userpass/tune
Key                  Value
---                  -----
default_lease_ttl    768h
...                  ...
max_lease_ttl        768h
...                  ...
```

Nota:
* default-lease-ttl determines the initial lifespan of a token if no specific TTL is provided
* max-lease-ttl limits how long a token can be renewed for

```
root@cli-ansible-vault:~# vault auth tune -max-lease-ttl=24h userpass
root@cli-ansible-vault:~# vault auth tune -default-lease-ttl=24h userpass
```

```
root@cli-ansible-vault:~# vault read sys/auth/userpass/tune
Key                  Value
---                  -----
default_lease_ttl    24h
...                  ...
max_lease_ttl        24h
...                  ...
```