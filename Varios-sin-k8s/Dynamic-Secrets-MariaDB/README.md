# Index:

* [Prerequisites](#id10)
* [Instalación de MariaDB](#id20)
* [Configuración de Vault para MariaDB](#id30)
* [Permitir hacer login en Vault](#id40)
* [Acceso al MariaDB](#id50)


# Prerequisites <div id='id10' />

Necesidades:

* Equipo con Vault desplegado (sin H.A.) en docker-compose
* Un S.O. limpio, para poder instalar MariaDB

# Instalación de MariaDB <div id='id20' /> 

```
root@mariadb-server:~# apt update && apt install -y mariadb-server
root@mariadb-server:~# systemctl start mariadb && systemctl enable mariadb
root@mariadb-server:~# mariadb-secure-installation
```

```
root@mariadb-server:~# mariadb -u root -p

MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'sorisat' WITH GRANT OPTION;
MariaDB [(none)]> FLUSH PRIVILEGES;

MariaDB [(none)]> CREATE DATABASE ilba;
MariaDB [(none)]> USE ilba;

CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    edad INT
);

INSERT INTO usuarios (nombre, apellido, edad) VALUES ('Oscar', 'Mas', 49);
INSERT INTO usuarios (nombre, apellido, edad) VALUES ('Abril', 'Mas', 19);
INSERT INTO usuarios (nombre, apellido, edad) VALUES ('Genis', 'Mas', 15);
INSERT INTO usuarios (nombre, apellido, edad) VALUES ('Nuria', 'Ilari', 48);

MariaDB [ilba]> SELECT * FROM usuarios;
+----+--------+----------+------+
| id | nombre | apellido | edad |
+----+--------+----------+------+
|  1 | Oscar  | Mas      |   49 |
|  2 | Abril  | Mas      |   19 |
|  3 | Genis  | Mas      |   15 |
|  4 | Nuria  | Ilari    |   48 |
+----+--------+----------+------+
4 rows in set (0.001 sec)
```

```
root@mariadb-server:~# vim /etc/mysql/mariadb.conf.d/50-server.cnf
bind-address            = 0.0.0.0

root@mariadb-server:~# systemctl restart mariadb
```

# Configuración de Vault para MariaDB <div id='id30' />

```
root@vault:~# docker ps -a
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS         PORTS                                 NAMES
7f35758614e6   nginx:1.29.8-alpine      "/docker-entrypoint.…"   6 minutes ago   Up 6 minutes   0.0.0.0:80->80/tcp, [::]:80->80/tcp   nginx
0854f6305795   hashicorp/vault:1.21.4   "docker-entrypoint.s…"   6 minutes ago   Up 6 minutes   8200/tcp                              vault

root@vault:~# docker exec -it vault ash

/ # vault status
Key             Value
---             -----
...
Sealed          false
...
```

```
/ # export VAULT_ADDR=http://127.0.0.1:8200
/ # vault login s.KaU83zJXYPXaZZCfFkgT8eJX

/ # vault secrets enable -path=mariadb database

/ # vault write mariadb/config/my-mysql-database \
plugin_name=mysql-database-plugin \
connection_url="{{username}}:{{password}}@tcp(172.26.0.29:3306)/ilba" \
allowed_roles="my-role" \
username="root" \
password="sorisat"

/ # vault write mariadb/roles/my-role \
db_name=my-mysql-database \
creation_statements="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON ilba.* TO '{{name}}'@'%';" \
default_ttl="1h" \
max_ttl="24h"
```

Verificaciones

```
/ # vault list mariadb/roles
/ # vault list mariadb/config
/ # vault read -format=json mariadb/roles/my-role
/ # vault read -format=json mariadb/config/my-mysql-database
```

# Permitir hacer login en Vault <div id='id40' />

```
/ # vault policy write policy-myapp - <<EOF
path "mariadb/creds/my-role" {
  capabilities = ["read"]
}
EOF

/ # vault auth enable userpass

/ # vault write auth/userpass/users/oscar.mas \
password="superpassword" \
policies="policy-myapp"
```

# Acceso al MariaDB <div id='id50' />

Desde un equipo cliente, le solicitaremos a Vault el usuario y el password, para poder acceder al MariaDB:

```
$ export VAULT_ADDR='http://172.26.0.30'
$ vault login -method=userpass username=oscar.mas

$ vault read mariadb/creds/my-role
Key                Value
---                -----
lease_id           mariadb/creds/my-role/qpHUQUIUajXUurJbpuAOWaM0
lease_duration     1h
lease_renewable    true
password           9aDov-0mzTGu9O5FeMKR
username           v-userpass-o-my-role-OuDxxcREtkv
```

```
$ mariadb -u v-userpass-o-my-role-OuDxxcREtkv -p -h 172.26.0.29

MariaDB [(none)]> USE ilba;

MariaDB [ilba]> SELECT * FROM usuarios;
+----+--------+----------+------+
| id | nombre | apellido | edad |
+----+--------+----------+------+
|  1 | Oscar  | Mas      |   49 |
|  2 | Abril  | Mas      |   19 |
|  3 | Genis  | Mas      |   15 |
|  4 | Nuria  | Ilari    |   48 |
+----+--------+----------+------+
4 rows in set (0.013 sec)
```