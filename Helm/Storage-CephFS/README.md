# Ceph Storage FileSystem

* [Creación de un CpehFS](#id0)
* [CephFS Path Restriction](#id10)

## Creación de un CpehFS <div id='id0' />

```
root@ceph-01:~# ceph version
ceph version 16.2.9 (4c3647a322c0ff5a1dd2344e039859dcbd28c830) pacific (stable)

root@ceph-01:~# ceph fs volume ls
[]

root@ceph-01:~# ceph fs flag set enable_multiple true
root@ceph-01:~# ceph fs volume create client-01
root@ceph-01:~# ceph fs volume create client-02

root@ceph-01:~# ceph fs volume ls
[
    {
        "name": "client-01"
    },
    {
        "name": "client-02"
    }
]

root@ceph-01:~# ceph osd pool set cephfs.client-01.meta size 2         
root@ceph-01:~# ceph osd pool set cephfs.client-01.data size 2 

root@ceph-01:~# ceph fs ls
name: client-01, metadata pool: cephfs.client-01.meta, data pools: [cephfs.client-01.data ]
name: client-02, metadata pool: cephfs.client-02.meta, data pools: [cephfs.client-02.data ]

root@ceph-01:~# ceph fs authorize client-01 client.usuario-01 / rw                
[client.usuario-01]
        key = AQABTr1iqBEfNBAAQPYCACNJJl6VLgMcIsWQsw==

root@ceph-01:~# ceph auth get client.usuario-01
[client.usuario-01]
        key = AQABTr1iqBEfNBAAQPYCACNJJl6VLgMcIsWQsw==
        caps mds = "allow rw fsname=client-01"
        caps mon = "allow r fsname=client-01"
        caps osd = "allow rw tag cephfs data=client-01"
exported keyring for client.usuario-01
```

Verificaciones del acceso:

```
root@ceph-01:~# ceph auth get client.usuario-01 > ceph.client.usuario-01.keyring

root@ceph-01:~# ceph fs ls -n client.usuario-01 -k ceph.client.usuario-01.keyring
name: client-01, metadata pool: cephfs.client-01.meta, data pools: [cephfs.client-01.data ]

root@ceph-01:~# apt-get update && apt-get install -y ceph-fuse

root@ceph-01:~# ceph-fuse /mnt -n client.usuario-01 -k ceph.client.usuario-01.keyring --client-fs=client-01

root@ceph-01:~# mount | grep ceph-fuse
ceph-fuse on /mnt type fuse.ceph-fuse (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)
```

Verificaciones en remoto:

```
root@ceph-01:~# scp ceph.client.usuario-01.keyring packer:
root@ceph-01:~# scp /etc/ceph/ceph.conf packer:/etc/ceph/ceph.conf

root@packer:~# ceph-fuse /mnt -n client.usuario-01 -k ceph.client.usuario-01.keyring

root@packer:~# mount | grep ceph-fuse
ceph-fuse on /mnt type fuse.ceph-fuse (rw,nosuid,nodev,relatime,user_id=0,group_id=0,allow_other)
```

## CephFS Path Restriction <div id='id10' />

En vista del consejo que nos brinda Ceph, probamos el modelo de trabajar con carpetas:

```
root@ceph-01:~# ceph auth get client.admin
[client.admin]
        key = AQACm+9hqdq1GBAAQM/e9QUpQM8LymVNRnsIHw==
        caps mds = "allow *"
        caps mgr = "allow *"
        caps mon = "allow *"
        caps osd = "allow *"
exported keyring for client.admin

root@ceph-01:~# mount -t ceph 172.26.10.61:6789:/ /mnt/ -o name=admin,secret=AQACm+9hqdq1GBAAQM/e9QUpQM8LymVNRnsIHw==
root@ceph-01:~# mkdir /mnt/client{1..2}
root@ceph-01:~# echo "password1" > /mnt/client1/secret.txt && echo "password2" > /mnt/client2/secret.txt
root@ceph-01:~# umount /mnt/

root@ceph-01:~# ceph fs authorize cephfs client.usuario1 /client1 rw
root@ceph-01:~# ceph fs authorize cephfs client.usuario2 /client2 rw

root@ceph-01:~# ceph auth get-key client.usuario1 && echo
AQBmpoRiB53yNBAAnxuUIHJrw7fcfIFpB6xsiw==

root@ceph-01:~# ceph auth get-key client.usuario2 && echo 
AQBtpoRispqELBAA3cnBrKAbEAoxYJUeRTAb/A==

# Añadir tarjeta de red al cluster de debian en la LAN 172.26.10.0/24 + conbfiguración de las eth

➜  ~ (mi-casa-ubuntu:default) k ctx mi-casa-debian
➜  ~ (mi-casa-debian:default) k create ns cephfs && k ns cephfs

k create secret generic ceph-usuario1-secret \
--from-literal=key='AQBmpoRiB53yNBAAnxuUIHJrw7fcfIFpB6xsiw==' \
--namespace=cephfs

k create secret generic ceph-usuario2-secret \
--from-literal=key='AQBtpoRispqELBAA3cnBrKAbEAoxYJUeRTAb/A==' \
--namespace=cephfs

cat <<EOF > cephfs-pv-pvc-usuarios.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: cephfs-pv-usuario1
  namespace: cephfs
spec:
  capacity:
    storage: 3Gi
  accessModes:
    - ReadWriteMany
  cephfs:
    monitors:
      - 172.26.10.61:6789, 172.26.10.62:6789, 172.26.10.63:6789
    user: usuario1
    path: /client1
    secretRef:
      name: ceph-usuario1-secret
    readOnly: false
  persistentVolumeReclaimPolicy: Recycle
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pv-usuario1
  namespace: cephfs
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF

cat <<EOF > cephfs-deployment-usuarios.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: httpd-usuario1
  namespace: cephfs
spec:
  selector:
    matchLabels:
      app: httpd-usuario1
  replicas: 3
  template:
    metadata:
       labels:
          app: httpd-usuario1
       name: nginx
    spec:
      containers:
      - name: httpd-usuario1
        image: httpd
        ports:
        - containerPort: 80
        volumeMounts:
          - mountPath: "/mnt/cephfs"
            name: cephfs-vol
            readOnly: false
      volumes:
      - name: cephfs-vol
        persistentVolumeClaim:
          claimName: cephfs-pv-usuario1
EOF

################ EN TODOS LOS NODOS INCLUSO EN EL MASTER ################
ssh 172.26.0.33 -C 'apt-get update && apt install -y ceph-common'
ssh 172.26.0.34 -C 'apt-get update && apt install -y ceph-common'
ssh 172.26.0.35 -C 'apt-get update && apt install -y ceph-common'
################ EN TODOS LOS NODOS INCLUSO EN EL MASTER ################

➜  ~ (mi-casa-debian:cephfs) kcaf cephfs-pv-pvc-usuarios.yaml
➜  ~ (mi-casa-debian:cephfs) kcaf cephfs-deployment-usuarios.yaml

➜  ~ (mi-casa-debian:cephfs) k get pods

➜  ~ (mi-casa-debian:cephfs) POD=`k get pods | grep httpd | head -1 | awk '{print $1}'`
➜  ~ (mi-casa-debian:cephfs) k exec -ti $POD -- bash

root@httpd-usuario1-6598496ff4-bgnjh:/usr/local/apache2# df -h | grep cephfs
172.26.10.61:6789,172.26.10.62:6789,172.26.10.63:6789:/client1  163G  524M  163G   1% /mnt/cephfs

root@httpd-usuario1-6598496ff4-bgnjh:/usr/local/apache2# cat /mnt/cephfs/secret.txt
password1
```
