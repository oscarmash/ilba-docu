# Operator MariaDB

* [Getting Started](#id0)
* [Instalación del operator](#id10)
* [Despliegue de BBDD (Standalone)](#id20)
  * [Desplegar BBDD](#id21)
  * [Añadir datos a la BBDD desplegada](#id22)
  * [Como añadir una BBDD](#id23) :construction: **No empezado**
* [Gestión de los backups](#id30)
  * [Physical backup](#id31) :construction: **No acabado**
  * [Logical backups](#id32)
* [Restore de un backup](#id40)
* [Acceso desde fuera del cluster de K8s](#id50)
* [Monitrización con KPS](#id60) :construction: **No empezado**

## Getting Started <div id='id0' />

Ubicación del operator: https://github.com/mariadb-operator/mariadb-operator/blob/main/README.md

Partimos de la siguiente base:

* Tenemos un cluster de K8S desplegado
* Por experiencia propia: si no hay 3 wokers/nodes, no nos funcionará el sistema de storage de Ceph
* Tenemos un sistema de Ceph desplegado (en esta caso es un All-In-One)

Verificaremos que todo esté correcto

```
root@diba-master:~# kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
diba-master     Ready    control-plane   45d   v1.28.6
diba-master-1   Ready    <none>          45d   v1.28.6
diba-master-2   Ready    <none>          45d   v1.28.6
diba-master-3   Ready    <none>          45d   v1.28.6
```

```
root@ceph-aio:~# ceph -s
  cluster:
    id:     7d2b3cca-f1eb-11ee-a886-593bc87d3824
    health: HEALTH_OK
            (muted: POOL_NO_REDUNDANCY)

  services:
    mon: 1 daemons, quorum ceph-aio (age 95s)
    mgr: ceph-aio.iaeehz(active, since 42s)
    osd: 3 osds: 3 up (since 52s), 3 in (since 2M)

  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 449 KiB
    usage:   891 MiB used, 89 GiB / 90 GiB avail
    pgs:     1 active+clean
```

## Instalación del operator <div id='id10' />

```
root@k8s-test-cp:~# helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operator && helm repo update

root@k8s-test-cp:~# helm search repo mariadb-operator/mariadb-operator-crds | grep mariadb-operator | awk '{print $2}'
25.8.3

root@k8s-test-cp:~# vim values-mariadb-operator.yaml
crds:
  enabled: false
ha:
  enabled: true
  replicas: 3

root@k8s-test-cp:~# helm upgrade --install \
mariadb-operator-crds mariadb-operator/mariadb-operator-crds \
--create-namespace \
--namespace mariadb-operator \
--version=25.8.3

root@k8s-test-cp:~# helm upgrade --install \
mariadb-operator mariadb-operator/mariadb-operator \
--create-namespace \
--namespace mariadb-operator \
--version=25.8.3 \
-f values-mariadb-operator.yaml

root@k8s-test-cp:~# kubectl -n mariadb-operator get pods
NAME                                                READY   STATUS    RESTARTS   AGE
mariadb-operator-7f8dc6f475-8tmvz                   1/1     Running   0          2m47s
mariadb-operator-7f8dc6f475-gkjs2                   1/1     Running   0          2m47s
mariadb-operator-7f8dc6f475-v7k7n                   1/1     Running   0          2m47s
mariadb-operator-cert-controller-67f78fc9f4-ch5pc   1/1     Running   0          2m47s
mariadb-operator-webhook-5d8c997f76-t8smr           1/1     Running   0          2m47s
```

Revisar que haya un StorageClass por defecto:

```
root@k8s-test-cp:~# k get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   49d
```

## Despliegue de BBDD (Standalone) <div id='id20' />

### Desplegar BBDD <div id='id21' />

Primero crearemos un NS para poder trabajar en el:

```
root@k8s-test-cp:~# k create ns test-mariadb-operator
```

Manifest del operator:

```
root@k8s-test-cp:~# vim test-mariadb-operator.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-operator-secrets
  namespace: test-mariadb-operator
data:
  MARIADB_PASSWORD: c29yaXNhdA== #sorisat
  MARIADB_ROOT_PASSWORD: c29yaXNhdA== #sorisat
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: mariadb-operator
  namespace: test-mariadb-operator
spec:
  image: mariadb:10.11.3
  database: mariadb-operator-bbdd
  rootPasswordSecretKeyRef:
    name: mariadb-operator-secrets
    key: MARIADB_ROOT_PASSWORD
  updateStrategy:
    type: ReplicasFirstPrimaryLast
  storage:
    size: 5Gi
    resizeInUseVolumes: true
    waitForVolumeResize: true
    storageClassName: csi-rbd-sc
    volumeClaimTemplate:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
      storageClassName: csi-rbd-sc
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: mariadb-operator-user
  namespace: test-mariadb-operator
spec:
  mariaDbRef:
    name: mariadb-operator
  passwordSecretKeyRef:
    name: mariadb-operator-secrets
    key: MARIADB_PASSWORD
  maxUserConnections: 5
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: mariadb-operator-grant
  namespace: test-mariadb-operator
spec:
  mariaDbRef:
    name: mariadb-operator
  privileges:
  - ALL PRIVILEGES
  database: mariadb-operator-bbdd
  username: mariadb-operator-user
```

:warning: El siguiente paso tarda unos 5 minutos :warning:

Aplicamos el Manifest y verificamos su funcionamiento:

```
root@k8s-test-cp:~# k apply -f test-mariadb-operator.yaml
```

```
root@k8s-test-cp:~# kubectl -n test-mariadb-operator get pods
NAME                 READY   STATUS    RESTARTS      AGE
mariadb-operator-0   1/1     Running   1 (32s ago)   2m16s

root@k8s-test-cp:~# kubectl -n test-mariadb-operator get mariadbs
NAME               READY   STATUS    PRIMARY              UPDATES                    AGE
mariadb-operator   True    Running   mariadb-operator-0   ReplicasFirstPrimaryLast   2m29s

root@k8s-test-cp:~# k -n test-mariadb-operator get users
NAME                           READY   STATUS    MAXCONNS   MARIADB            AGE
mariadb-operator-mariadb-sys   True    Created   20         mariadb-operator   55s
mariadb-operator-user          True    Created   5          mariadb-operator   3m1s

root@k8s-test-cp:~# k -n test-mariadb-operator get databases
NAME                        READY   STATUS    CHARSET   COLLATE           MARIADB            AGE   NAME
mariadb-operator-database   True    Created   utf8      utf8_general_ci   mariadb-operator   71s   mariadb-operator-bbdd
```

### Añadir datos a la BBDD desplegada <div id='id22' />

Aprovecharemos para meter datos en la BBDD:

```
root@k8s-test-cp:~# k -n test-mariadb-operator exec -it mariadb-operator-0 -- bash

mysql@mariadb-operator-0:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/rbd0       4.9G  125M  4.8G   3% /var/lib/mysql
...

mysql@ilba-mariadb-operator-0:/$ mysql -u root -p

MariaDB [(none)]> SELECT VERSION();
+-----------------------------------------+
| VERSION()                               |
+-----------------------------------------+
| 10.11.3-MariaDB-1:10.11.3+maria~ubu2204 |
+-----------------------------------------+
1 row in set (0.000 sec)

MariaDB [(none)]> SHOW DATABASES;
+----------------------------+
| Database                   |
+----------------------------+
| #mysql50#lost+found        |
| ilba-mariadb-operator-bbdd |
| information_schema         |
| mysql                      |
| performance_schema         |
| sys                        |
+----------------------------+
6 rows in set (0.001 sec)

MariaDB [(none)]> USE mariadb-operator-bbdd;

MariaDB [mariadb-operator-bbdd]> CREATE TABLE datos (id INT, nombre VARCHAR(20), apellido VARCHAR(20));
MariaDB [mariadb-operator-bbdd]> INSERT INTO datos (id,nombre,apellido) VALUES(1,"Oscar","Mas");
MariaDB [mariadb-operator-bbdd]> INSERT INTO datos (id,nombre,apellido) VALUES(2,"Nuria","Ilari");

MariaDB [mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.001 sec)

MariaDB [mariadb-operator-bbdd]> quit
mysql@mariadb-operator-0:/$ exit
```

### Como añadir una BBDD <div id='id21' />

XXXXSSSSSS

## Gestión de los backups <div id='id30' />

Los backups que se pueden hacer con el operator de MariaDB son:
* [Physical backups](https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/physical_backup.md#what-is-a-physical-backup): Physical backups are the recommended method for backing up MariaDB databases, especially in production environments, as they are faster and more efficient than logical backups.
  * Physical backups can only be restored in brand new MariaDB instances without any existing data. This means that you cannot restore a physical backup into an existing MariaDB instance that already has data.
* [Logical backups](https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/logical_backup.md#what-is-a-logical-backup): A logical backup is a backup that contains the logical structure of the database, such as tables, indexes, and data, rather than the physical storage format. It is created using mariadb-dump, which generates SQL statements that can be used to recreate the database schema and populate it with data.

### Physical backups <div id='id31' />

Verificamos los datos actuales de la BBDD:

```
root@k8s-test-cp:~# k -n test-mariadb-operator exec -it mariadb-operator-0 -- bash
mysql@mariadb-operator-0:/$ mysql -u root -p
MariaDB [(none)]> USE mariadb-operator-bbdd;

MariaDB [mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.001 sec)

MariaDB [mariadb-operator-bbdd]> quit
mysql@mariadb-operator-0:/$ exit
```

```
root@k8s-test-cp:~# vim test-mariadb-operator-physicalbackup-now.yaml
apiVersion: k8s.mariadb.com/v1alpha1
kind: PhysicalBackup
metadata:
  name: test-mariadb-operator-physicalbackup
  namespace: test-mariadb-operator
spec:
  mariaDbRef:
    name: mariadb-operator
  storage:
    s3:
      bucket: mariadb-operator-backups
      endpoint: 172.26.0.35:9000
      secretAccessKeySecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_SECRET_KEY
      accessKeyIdSecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_ACCESS_KEY
      tls:
        enabled: false

root@k8s-test-cp:~# k apply -f test-mariadb-operator-physicalbackup-now.yaml

root@k8s-test-cp:~# k -n test-mariadb-operator get PhysicalBackup
NAME                                   COMPLETE   STATUS    MARIADB            LAST SCHEDULED   AGE
test-mariadb-operator-physicalbackup   True       Success   mariadb-operator   33s              33s
```

**NOTA:** Hemos de tener configurado el cliente de MinIO

```
root@k8s-test-cp:~# ./mc_minio ls StorageS3/mariadb-operator-backups/
[2025-09-11 11:47:18 CEST]  16MiB STANDARD physicalbackup-20250911094714.xb
```

Eliminamos los datos para hacer la restauración:

```
root@k8s-test-cp:~# k -n test-mariadb-operator exec -it mariadb-operator-0 -- bash
mysql@mariadb-operator-0:/$ mysql -u root -p

MariaDB [(none)]> USE mariadb-operator-bbdd;

MariaDB [mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.074 sec)

MariaDB [mariadb-operator-bbdd]> DELETE FROM datos WHERE id='2';

MariaDB [mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
+------+--------+----------+
1 row in set (0.001 sec)

MariaDB [mariadb-operator-bbdd]> exit
mysql@mariadb-operator-0:/$ exit
```

Antes de restaurar hemos de eliminar la BBDD:

```
root@k8s-test-cp:~# k -n test-mariadb-operator delete mariadbs mariadb-operator
root@k8s-test-cp:~# k -n test-mariadb-operator delete --all pods
root@k8s-test-cp:~# k -n test-mariadb-operator delete pvc storage-mariadb-operator-0
```

Restauramos:

```
root@k8s-test-cp:~# vim test-mariadb-operator-physicalbackup-restore.yaml

```





























### Logical backups <div id='id32' />

Procedimiento previo:

* Creamos un bucket en [MinIO](http://172.26.0.35:9001/) -> mariadb-operator-backups
* Access Key que nos ha dado Minio:
  * Name: mariadb-operator-backups
  * Access Key: 85kAT9sBv3XJicxuGFWP
  * Secret Key: bz7bGHPSEkdBTrUUqiSBB1DZjidJWEZ544Z2KHic

Verificamos los datos de acceso al S3:

```
root@k8s-test-cp:~# curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc_minio
root@k8s-test-cp:~# EDPOINT="http://172.26.0.35:9000"
root@k8s-test-cp:~# KEY="bz7bGHPSEkdBTrUUqiSBB1DZjidJWEZ544Z2KHic"
root@k8s-test-cp:~# KEY_ID="85kAT9sBv3XJicxuGFWP"

root@k8s-test-cp:~# chmod +x mc_minio
root@k8s-test-cp:~# ./mc_minio alias set StorageS3 $EDPOINT $KEY_ID $KEY

root@k8s-test-cp:~# ./mc_minio alias ls StorageS3
StorageS3
  URL       : http://172.26.0.35:9000
  AccessKey : 85kAT9sBv3XJicxuGFWP
  SecretKey : bz7bGHPSEkdBTrUUqiSBB1DZjidJWEZ544Z2KHic
  API       : s3v4
  Path      : auto
  Src       : /root/.mc_minio/config.json

```

Creamos el Manifest para gestionar los backups:

```
root@k8s-test-cp:~# vim test-mariadb-operator-backup.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-operator-secrets-bucket
  namespace: test-mariadb-operator
data:
  MINIO_SECRET_KEY: Yno3YkdIUFNFa2RCVHJVVXFpU0JCMURaamlkSldFWjU0NFoyS0hpYw== #echo -n "bz7bGHPSEkdBTrUUqiSBB1DZjidJWEZ544Z2KHic" | base64
  MINIO_ACCESS_KEY: ODVrQVQ5c0J2M1hKaWN4dUdGV1A= #echo -n "85kAT9sBv3XJicxuGFWP" | base64
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: Backup
metadata:
  name: test-mariadb-operator-backup
  namespace: test-mariadb-operator
spec:
  mariaDbRef:
    name: mariadb-operator
  schedule:
    cron: "0 1 * * *"
    suspend: false
  maxRetention: 48h
  compression: gzip
  storage:
    s3:
      bucket: mariadb-operator-backups
      prefix: mariadb-folder
      endpoint: 172.26.0.35:9000
      secretAccessKeySecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_SECRET_KEY
      accessKeyIdSecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_ACCESS_KEY
      tls:
        enabled: false
```

Aplicamos los canvios y verificamos:

```
root@k8s-test-cp:~# k apply -f test-mariadb-operator-backup.yaml

root@k8s-test-cp:~# k -n test-mariadb-operator get backups
NAME                           COMPLETE   STATUS      MARIADB            AGE
test-mariadb-operator-backup   False      Scheduled   mariadb-operator   8s

root@k8s-test-cp:~# k -n test-mariadb-operator get cronjobs
NAME                           SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
test-mariadb-operator-backup   0 1 * * *   <none>     False     0        <none>          23s
```

Lanzaremos un job y verificaremos en el S3 que están los datos:

```
root@k8s-test-cp:~# vim test-mariadb-operator-backup-now.yaml
apiVersion: k8s.mariadb.com/v1alpha1
kind: Backup
metadata:
  name: test-mariadb-operator-backup
  namespace: test-mariadb-operator
spec:
  mariaDbRef:
    name: mariadb-operator
  maxRetention: 48h
  compression: gzip
  storage:
    s3:
      bucket: mariadb-operator-backups
      prefix: mariadb-folder
      endpoint: 172.26.0.35:9000
      secretAccessKeySecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_SECRET_KEY
      accessKeyIdSecretKeyRef:
        name: mariadb-operator-secrets-bucket
        key: MINIO_ACCESS_KEY
      tls:
        enabled: false

root@k8s-test-cp:~# k apply -f test-mariadb-operator-backup-now.yaml

root@k8s-test-cp:~# k -n test-mariadb-operator get backups
NAME                           COMPLETE   STATUS    MARIADB            AGE
test-mariadb-operator-backup   True       Success   mariadb-operator   2m14s

root@k8s-test-cp:~# ./mc_minio ls StorageS3/mariadb-operator-backups/mariadb-folder/
[2025-09-11 11:28:59 CEST] 514KiB STANDARD backup.2025-09-11T09:28:57Z.gzip.sql
```

## Restore de un backup <div id='id40' />

Aprovechando el backup que hemos realizado anteriormente, borraremos una fila en la actual BBDD, para cuando se restaure podamos verificar el correcto funcionamiento:

```
root@k8s-test-cp:~# k -n test-ilba-mariadb-operator exec -it ilba-mariadb-operator-0 -- bash

mysql@ilba-mariadb-operator-0:/$ mysql -u root -p

MariaDB [(none)]> USE ilba-mariadb-operator-bbdd;

MariaDB [ilba-mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.001 sec)

MariaDB [ilba-mariadb-operator-bbdd]> DELETE FROM datos WHERE id='2';

MariaDB [ilba-mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
+------+--------+----------+
1 row in set (0.001 sec)

MariaDB [ilba-mariadb-operator-bbdd]> exit
mysql@ilba-mariadb-operator-0:/$ exit
```

Podremos ver el fichero del backup, de esta manera sabremos el fichero a restaurar:

```
root@k8s-test-cp:~# ./mc_minio ls StorageS3/mariadb-operator-backups/mariadb-ilba-folder/
[2025-06-28 10:27:14 CEST] 514KiB STANDARD backup.2025-06-28T08:27:13Z.gzip.sql
```

Creamos el Manifest:

```
root@k8s-test-cp:~# vim test-mariadb-operator-restore.yaml
apiVersion: k8s.mariadb.com/v1alpha1
kind: Restore
metadata:
  name: ilba-mariadb-operator-restore
  namespace: test-ilba-mariadb-operator
spec:
  mariaDbRef:
    name: ilba-mariadb-operator
  backupRef:
    name: test-mariadb-operator-backup
  targetRecoveryTime: 2025-06-28T08:27:13Z
  database: ilba-mariadb-operator-bbdd
  s3:
    bucket: mariadb-operator-backups
    prefix: mariadb-ilba-folder
    endpoint: 172.26.0.35:9000
    secretAccessKeySecretKeyRef:
      name: ilba-mariadb-operator-secrets-bucket
      key: MINIO_SECRET_KEY
    accessKeyIdSecretKeyRef:
      name: ilba-mariadb-operator-secrets-bucket
      key: MINIO_ACCESS_KEY
    tls:
      enabled: false
```

Aplicamos el manifest y verificamos que se haya restaurado la fila que hemos borrado con anterioridad.

```
root@k8s-test-cp:~# k apply -f test-mariadb-operator-restore.yaml

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get restore
NAME                            COMPLETE   STATUS    MARIADB                 AGE
ilba-mariadb-operator-restore   True       Success   ilba-mariadb-operator   8s

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator exec -it ilba-mariadb-operator-0 -- bash

mysql@ilba-mariadb-operator-0:/$ mysql -u root -p

MariaDB [(none)]> USE ilba-mariadb-operator-bbdd;

MariaDB [ilba-mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.001 sec)
```

## Acceso desde fuera del cluster de K8s <div id='id50' />

```
root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get svc
NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
ilba-mariadb-operator            ClusterIP   10.233.54.165   <none>        3306/TCP   11h
ilba-mariadb-operator-internal   ClusterIP   None            <none>        3306/TCP   11h

root@k8s-test-cp:~# k -n metallb-system get IPAddressPool
NAME        AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
base-pool   true          false             ["172.26.0.101/32"]

root@k8s-test-cp:~# vim test-mariadb-operator-IPAddressPool.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: mariadb-operator
  namespace: metallb-system
spec:
  addresses:
  - 172.26.0.102/32

root@k8s-test-cp:~# k apply -f test-mariadb-operator-IPAddressPool.yaml

root@k8s-test-cp:~# k -n metallb-system get IPAddressPool
NAME               AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
base-pool          true          false             ["172.26.0.101/32"]
mariadb-operator   true          false             ["172.26.0.102/32"]

root@k8s-test-cp:~# vim test-mariadb-operator.yaml
...
spec:
  service:
    type: LoadBalancer
    metadata:
      annotations:
        metallb.universe.tf/loadBalancerIPs: 172.26.0.102
  ...

root@k8s-test-cp:~# k apply -f test-mariadb-operator.yaml

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get svc
NAME                             TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)          AGE
ilba-mariadb-operator            LoadBalancer   10.233.54.165   172.26.0.102   3306:30409/TCP   11h
ilba-mariadb-operator-internal   ClusterIP      None            <none>         3306/TCP         11h
```

## Monitrización con KPS <div id='id60' />

URL de interes:
* https://github.com/mariadb-operator/mariadb-operator/blob/main/docs/metrics.md