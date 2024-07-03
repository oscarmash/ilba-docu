# Operator MariaDB

* [Getting Started](#id0)
* [Instalación](#id10)
* [Funcionamiento](#id20)

## Getting Started <div id='id0' />

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

## Instalación <div id='id10' />

Instalación del Operator

```
root@diba-master:~# helm repo add mariadb-operator https://helm.mariadb.com/mariadb-operator
root@diba-master:~# helm repo update

helm upgrade --install \
mariadb-operator mariadb-operator/mariadb-operator \
--create-namespace \
--namespace mariadb-operator \
--version=0.29.0

root@diba-master:~# kubectl -n mariadb-operator get pods
NAME                                               READY   STATUS    RESTARTS   AGE
mariadb-operator-7545889c95-sq6vv                  1/1     Running   0          18s
mariadb-operator-cert-controller-8b7fc8d67-jzlnb   0/1     Running   0          18s
mariadb-operator-webhook-77557c8867-ts744          0/1     Running   0          18s
```

```
root@diba-master:~# kubectl create ns mi-mariadb
root@diba-master:~# kubectl config set-context --current --namespace=mi-mariadb

Revisar que haya un StorageClass por defecto:

root@diba-master:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   5h19m

root@diba-master:~# git clone https://github.com/mariadb-operator/mariadb-operator.git

root@diba-master:~# sed -i 's/172.18.0.20/172.26.0.102/g' mariadb-operator/examples/manifests/mariadb.yaml

root@diba-master:~# sed -i 's/name: mariadb-root/name: mariadb/g' mariadb-operator/examples/manifests/mariadb.yaml
root@diba-master:~# sed -i 's/name: mariadb-password/name: mariadb/g' mariadb-operator/examples/manifests/mariadb.yaml

root@diba-master:~# sed -i 's/generate: true/generate: false/g' mariadb-operator/examples/manifests/mariadb.yaml

root@diba-master:~# kubectl apply -f mariadb-operator/examples/manifests/config/mariadb-secret.yaml
root@diba-master:~# kubectl apply -f mariadb-operator/examples/manifests/mariadb.yaml

root@diba-master:~# kubectl create secret generic mariadb-root --from-literal=password='MariaDB11!'
root@diba-master:~# kubectl create secret generic mariadb-password --from-literal=password='MariaDB11!'

root@diba-master:~# apt-get update && apt-get install -y jq
root@diba-master:~# kubectl get secret mariadb --template="{{.data.password}}" | base64 --decode && echo
MariaDB11!
```

## Funcionamiento <div id='id20' />

```

root@diba-master:~# kubectl get pods
NAME        READY   STATUS    RESTARTS      AGE
mariadb-0   1/1     Running   1 (24s ago)   93s

root@diba-master:~# kubectl get mariadbs
NAME      READY   STATUS    PRIMARY POD   AGE
mariadb   True    Running   mariadb-0     5m58s

root@diba-master:~# kubectl get databases
NAME               READY   STATUS    CHARSET   COLLATE           MARIADB   AGE   NAME
mariadb-database   True    Created   utf8      utf8_general_ci   mariadb   10m   mariadb

root@diba-master:~# kubectl exec -it mariadb-0 -- bash

mysql@mariadb-0:/$ mysql -u root -p

MariaDB [(none)]> SHOW DATABASES;
+---------------------+
| Database            |
+---------------------+
| #mysql50#lost+found |
| information_schema  |
| mariadb             |
| mysql               |
| performance_schema  |
| sys                 |
+---------------------+
6 rows in set (0.028 sec)

root@diba-master:~# kubectl apply -f mariadb-operator/examples/manifests/database.yaml

root@diba-master:~# kubectl get databases
NAME               READY   STATUS    CHARSET   COLLATE           MARIADB   AGE   NAME
database           True    Created   utf8      utf8_general_ci   mariadb   11s
mariadb-database   True    Created   utf8      utf8_general_ci   mariadb   11m   mariadb

root@diba-master:~# kubectl exec -it mariadb-0 -- bash

mysql@mariadb-0:/$ mysql -u root -p

MariaDB [(none)]> SHOW DATABASES;
+---------------------+
| Database            |
+---------------------+
| #mysql50#lost+found |
| database            |
| information_schema  |
| mariadb             |
| mysql               |
| performance_schema  |
| sys                 |
+---------------------+
7 rows in set (0.001 sec)
```
