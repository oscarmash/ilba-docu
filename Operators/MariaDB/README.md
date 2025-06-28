# Operator MariaDB

* [Getting Started](#id0)
* [Instalación del operator](#id10)
* [Despliegue de BBDD con el operator](#id20)
* [Gestión de los backups](#id30)
* [Restore de un backup](#id40)
* [Acceso desde fuera del cluster de K8s](#id50)

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
root@k8s-test-cp:~# helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operato
root@k8s-test-cp:~# helm repo update

root@k8s-test-cp:~# cat values-mariadb-operator.yaml
crds:
  enabled: false
ha:
  enabled: true
  replicas: 3

root@k8s-test-cp:~# helm upgrade --install \
mariadb-operator-crds mariadb-operator/mariadb-operator-crds \
--create-namespace \
--namespace mariadb-operator \
--version=0.38.1

root@k8s-test-cp:~# helm upgrade --install \
mariadb-operator mariadb-operator/mariadb-operator \
--create-namespace \
--namespace mariadb-operator \
--version=0.38.1 \
-f values-mariadb-operator.yaml

root@k8s-test-cp:~# k -n mariadb-operator get pods
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

## Despliegue de BBDD con el operator Started <div id='id20' />

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
  name: ilba-mariadb-operator-secrets
  namespace: test-ilba-mariadb-operator
data:
  MARIADB_PASSWORD: c29yaXNhdA== #sorisat
  MARIADB_ROOT_PASSWORD: c29yaXNhdA== #sorisat
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: ilba-mariadb-operator
  namespace: test-ilba-mariadb-operator
spec:
  image: mariadb:10.11.3
  database: ilba-mariadb-operator-bbdd
  rootPasswordSecretKeyRef:
    name: ilba-mariadb-operator-secrets
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
  name: ilba-mariadb-operator-user
  namespace: test-ilba-mariadb-operator
spec:
  mariaDbRef:
    name: ilba-mariadb-operator
  passwordSecretKeyRef:
    name: ilba-mariadb-operator-secrets
    key: MARIADB_PASSWORD
  maxUserConnections: 5
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: ilba-mariadb-operator-grant
  namespace: test-ilba-mariadb-operator
spec:
  mariaDbRef:
    name: ilba-mariadb-operator
  privileges:
  - ALL PRIVILEGES
  database: ilba-mariadb-operator-bbdd
  username: ilba-mariadb-operator-user
```

Aplicamos el Manifest y verificamos su funcionamiento:

```
root@k8s-test-cp:~# k apply -f test-mariadb-operator.yaml

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get pods
NAME                      READY   STATUS    RESTARTS      AGE
ilba-mariadb-operator-0   1/1     Running   1 (87s ago)   2m54s

root@k8s-test-cp:~# kubectl -n test-ilba-mariadb-operator get mariadbs
NAMESPACE                    NAME                    READY   STATUS    PRIMARY                   UPDATES                    AGE
test-ilba-mariadb-operator   ilba-mariadb-operator   True    Running   ilba-mariadb-operator-0   ReplicasFirstPrimaryLast   3m23s

root@k8s-test-cp:~# kubectl -n test-ilba-mariadb-operator get users
NAME                                READY   STATUS    MAXCONNS   MARIADB                 AGE
ilba-mariadb-operator-mariadb-sys   True    Created   20         ilba-mariadb-operator   2m15s
ilba-mariadb-operator-user          True    Created   0          ilba-mariadb-operator   4m5s

root@k8s-test-cp:~# kubectl -n test-ilba-mariadb-operator get databases
NAME                             READY   STATUS    CHARSET   COLLATE           MARIADB                 AGE   NAME
ilba-mariadb-operator-database   True    Created   utf8      utf8_general_ci   ilba-mariadb-operator   18s   ilba-mariadb-operator-bbdd
```

Aprovecharemos para meter datos en la BBDD:

```
root@k8s-test-cp:~# k -n test-ilba-mariadb-operator exec -it ilba-mariadb-operator-0 -- bash

mysql@ilba-mariadb-operator-0:/$ df -h
Filesystem      Size  Used Avail Use% Mounted on
...
/dev/rbd1       4.9G  125M  4.8G   3% /var/lib/mysql
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

MariaDB [(none)]> USE ilba-mariadb-operator-bbdd;
MariaDB [ilba-mariadb-operator-bbdd]> CREATE TABLE datos (id INT, nombre VARCHAR(20), apellido VARCHAR(20));
MariaDB [ilba-mariadb-operator-bbdd]> INSERT INTO datos (id,nombre,apellido) VALUES(1,"Oscar","Mas");
MariaDB [ilba-mariadb-operator-bbdd]> INSERT INTO datos (id,nombre,apellido) VALUES(2,"Nuria","Ilari");

MariaDB [ilba-mariadb-operator-bbdd]> SELECT * FROM datos;
+------+--------+----------+
| id   | nombre | apellido |
+------+--------+----------+
|    1 | Oscar  | Mas      |
|    2 | Nuria  | Ilari    |
+------+--------+----------+
2 rows in set (0.001 sec)

mysql@ilba-mariadb-operator-0:/$ exit
```

## Gestión de los backups <div id='id30' />

Procedimiento previo:

* Creamos un bucket en MinIO -> mariadb-operator-backups
* Access Key que nos ha dado Minio:
  * Access Key: aLZujA17zfuMlucWx9eC
  * Secret Key: bOAQg09RKYZ6PqHYMkywla2KrrhZXW91mjly8Nzf

Verificamos los datos de acceso al S3:

```
root@k8s-test-cp:~# curl https://dl.min.io/client/mc/release/linux-amd64/mc -o mc_minio
root@k8s-test-cp:~# EDPOINT="http://172.26.0.35:9000"
root@k8s-test-cp:~# KEY="bOAQg09RKYZ6PqHYMkywla2KrrhZXW91mjly8Nzf"
root@k8s-test-cp:~# KEY_ID="aLZujA17zfuMlucWx9eC"

root@k8s-test-cp:~# ./mc_minio alias ls StorageS3
StorageS3
  URL       : http://172.26.0.35:9000
  AccessKey : aLZujA17zfuMlucWx9eC
  SecretKey : bOAQg09RKYZ6PqHYMkywla2KrrhZXW91mjly8Nzf
  API       : s3v4
  Path      : auto
  Src       : /root/.mc_minio/config.json

root@k8s-test-cp:~# ./mc_minio alias set StorageS3 $EDPOINT $KEY_ID $KEY
```

Creamos el Manifest para gestionar los backups:

```
root@k8s-test-cp:~# vim test-mariadb-operator-backup.yaml
apiVersion: v1
kind: Secret
metadata:
  name: ilba-mariadb-operator-secrets-bucket
  namespace: test-ilba-mariadb-operator
data:
  MINIO_SECRET_KEY: Yk9BUWcwOVJLWVo2UHFIWU1reXdsYTJLcnJoWlhXOTFtamx5OE56Zg== #echo -n "bOAQg09RKYZ6PqHYMkywla2KrrhZXW91mjly8Nzf" | base64
  MINIO_ACCESS_KEY: YUxadWpBMTd6ZnVNbHVjV3g5ZUM= #echo -n "aLZujA17zfuMlucWx9eC" | base64
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: Backup
metadata:
  name: test-mariadb-operator-backup
  namespace: test-ilba-mariadb-operator
spec:
  mariaDbRef:
    name: ilba-mariadb-operator
  schedule:
    cron: "0 1 * * *"
    suspend: false
  maxRetention: 48h
  compression: gzip
  storage:
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

Aplicamos los canvios y verificamos:

```
root@k8s-test-cp:~# k apply -f test-mariadb-operator-backup.yaml

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get backups
NAME                           COMPLETE   STATUS      MARIADB                 AGE
test-mariadb-operator-backup   False      Scheduled   ilba-mariadb-operator   14s

root@k8s-test-cp:~# k -n test-ilba-mariadb-operator get cronjobs
NAME                           SCHEDULE    TIMEZONE   SUSPEND   ACTIVE   LAST SCHEDULE   AGE
test-mariadb-operator-backup   0 1 * * *   <none>     False     0        <none>          110s
```

Lanzaremos un job y verificaremos en el S3 que están los datos:

```
root@k8s-test-cp:~# k -n test-ilba-mariadb-operator create job --from=cronjob/test-mariadb-operator-backup prueba-de-backup-manual

root@k8s-test-cp:~# ./mc_minio ls StorageS3/mariadb-operator-backups/mariadb-ilba-folder/
[2025-06-28 10:27:14 CEST] 514KiB STANDARD backup.2025-06-28T08:27:13Z.gzip.sql
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

MariaDB [ilba-mariadb-operator-bbdd]> quit
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
