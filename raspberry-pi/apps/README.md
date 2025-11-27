* [Aplicaciones](#id1)
  * [App de test](#id10)
  * [Tailscale](#id20)
  * [Rook Ceph](#id30)
    * [Instalación](#id31)
    * [Creación del cluster](#id32)
    * [Crush map](#id33)
    * [Dashboard](#id34)
    * [Creación del pool + SC](#id35)
* [Troubleshooting](#id100)
  * [Rook Ceph: toolbox](#id111)
  * [Rook Ceph: Recopilación de comandos](#id112)
  * [Rook Ceph: no encuentra los OSDs](#id113)

# Aplicaciones <div id='id1' />

## App de test (nginx) <div id='id10' />


```
$ cd $HOME/ilba/ilba-docu/raspberry-pi/apps/files
$ scp test-app-hello-kubernetes.yaml oscar.mas@172.26.0.111:
```

```
oscar.mas@2025-05:~ $ kcaf test-app-hello-kubernetes.yaml
```

```
oscar.mas@2025-05:~ $ k -n test-ingress get ingress
NAME               CLASS       HOSTS                              ADDRESS                                PORTS     AGE
app-ilba-ingress   cilium      test-ingress.172.26.0.110.nip.io   172.26.0.110                           80        3s

oscar.mas@2025-05:~ $ curl -s -H "Host: test-ingress.172.26.0.110.nip.io" 172.26.0.110
<html>
<h1>Hello Kubernetes</h1>
<body>
This is Nginx Server
</body>
</html>

oscar.mas@2025-05:~ $ curl -s test-ingress.172.26.0.110.nip.io
<html>
<h1>Hello Kubernetes</h1>
<body>
This is Nginx Server
</body>
</html>
```

## Tailscale <div id='id20' />

En el tailScale, se le han de dar los permisos de:
* Devices - Core (write scopes)
* Keys - Auth Keys (write scopes)

```
oscar.mas@2025-05:~ $ cat values-tailscale.yaml
oauth:
  clientId: "k4o..."
  clientSecret: "tskey-client-k4of..."
```

```
helm upgrade --install \
tailscale-operator tailscale/tailscale-operator \
--create-namespace \
--namespace tailscale \
--version=1.88.4 \
-f values-tailscale.yaml
```

```
oscar.mas@2025-05:~ $ cat test-app-hello-kubernetes.yaml
...
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tailscale
  namespace: test-ingress
spec:
  defaultBackend:
    service:
      name: app-ilba-service
      port:
        number: 8080
  ingressClassName: tailscale
  tls:
    - hosts:
        - test-ingress.chocolate-elnath.ts.net
```

## Rook Ceph <div id='id30' />

### Instalación <div id='id31' />

Crearemos las pariciones en los equipos:

```
oscar.mas@2025-07:~ $ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
zram0       254:0    0     0B  0 disk
nvme0n1     259:0    0 476.9G  0 disk
|-nvme0n1p1 259:1    0   512M  0 part /boot/firmware
`-nvme0n1p2 259:2    0 118.6G  0 part /

oscar.mas@2025-07:~ $ sudo cfdisk /dev/nvme0n1
  Type: Linux

oscar.mas@2025-07:~ $ lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
zram0       254:0    0     0B  0 disk
nvme0n1     259:0    0 476.9G  0 disk
|-nvme0n1p1 259:1    0   512M  0 part /boot/firmware
|-nvme0n1p2 259:2    0 118.6G  0 part /
`-nvme0n1p3 259:3    0 357.9G  0 part     <---
```

Etiquetaremos los nodos que llevaran las particiones (OSD's):

```
oscar.mas@2025-05:~ $ k get nodes
NAME      STATUS   ROLES                       AGE     VERSION
2025-05   Ready    control-plane,etcd,master   36d     v1.33.5+k3s1
2025-07   Ready    <none>                      36d     v1.33.5+k3s1
2025-09   Ready    <none>                      36d     v1.33.5+k3s1
2025-11   Ready    <none>                      4d11h   v1.33.5+k3s1

oscar.mas@2025-05:~ $ kubectl label node 2025-07 topology.rook.io/cephnode=true
oscar.mas@2025-05:~ $ kubectl label node 2025-09 topology.rook.io/cephnode=true
oscar.mas@2025-05:~ $ kubectl label node 2025-11 topology.rook.io/cephnode=true
```

Instalamos Rook Ceph:

```
oscar.mas@2025-05:~ $ vim values-rook.yaml
nodeSelector:
  topology.rook.io/cephnode: "true"
monitoring:
  enabled: true

oscar.mas@2025-05:~ $ helm repo add rook-ceph https://charts.rook.io/release && helm repo update
```

```
helm upgrade --install \
rook-ceph rook-ceph/rook-ceph \
--create-namespace \
--namespace rook-ceph \
--version=v1.18.7 \
-f values-rook.yaml
```

```
oscar.mas@2025-05:~ $ k ns rook-ceph

oscar.mas@2025-05:~ $ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
rook-ceph       rook-ceph       1               2025-11-20 22:25:30.481276743 +0100 CET deployed        rook-ceph-v1.18.7       v1.18.7

oscar.mas@2025-05:~ $ k get pods
NAME                                           READY   STATUS    RESTARTS   AGE
ceph-csi-controller-manager-5dc6b7cf95-jxfbh   1/1     Running   0          100s
rook-ceph-operator-7fffcf99d8-xjpcs            1/1     Running   0          100s
```

### Creación del cluster <div id='id32' />

```
$ cat <<EOF > rook-ceph-nvme.yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph-nvme
  namespace: rook-ceph
spec:
  cephVersion:
    image: quay.io/ceph/ceph:v19.2.3
    allowUnsupported: false
  dataDirHostPath: /var/lib/rook
  skipUpgradeChecks: false
  continueUpgradeAfterChecksEvenIfNotHealthy: false
  mon:
    count: 3
    allowMultiplePerNode: false
  mgr:
    count: 2
    allowMultiplePerNode: false
  dashboard:
    enabled: true
    ssl: false
  storage:
    useAllNodes: false
    useAllDevices: false
    nodes:
      - name: "2025-07"
        devices:
          - name: "nvme0n1p3"
      - name: "2025-09"
        devices:
          - name: "nvme0n1p3"
      - name: "2025-11"
        devices:
          - name: "nvme0n1p3"
EOF
```

```
oscar.mas@2025-05:~ $ k apply -f rook-ceph-nvme.yaml
```

```
oscar.mas@2025-05:~ $ kubectl -n rook-ceph get cephcluster
NAME             DATADIRHOSTPATH   MONCOUNT   AGE   PHASE         MESSAGE                 HEALTH   EXTERNAL   FSID
rook-ceph-nvme   /var/lib/rook     3          30s   Progressing   Configuring Ceph Mons
```

```
oscar.mas@2025-05:~ $ kubectl -n rook-ceph get cephcluster
NAME             DATADIRHOSTPATH   MONCOUNT   AGE   PHASE   MESSAGE                        HEALTH      EXTERNAL   FSID
rook-ceph-nvme   /var/lib/rook     3          17h   Ready   Cluster created successfully   HEALTH_OK              a4a44952-4dcf-4389-bfa7-745bfa633870
```

### Crush Map <div id='id32' />

```
oscar.mas@2025-05:~ $ k -n rook-ceph exec deploy/rook-ceph-tools -it -- bash

bash-5.1$ ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME         STATUS  REWEIGHT  PRI-AFF
-1         1.04846  root default
-5         0.34949      host 2025-07
 1   nvme  0.34949          osd.1         up   1.00000  1.00000
-7         0.34949      host 2025-09
 2   nvme  0.34949          osd.2         up   1.00000  1.00000
-3         0.34949      host 2025-11
 0   nvme  0.34949          osd.0         up   1.00000  1.00000

bash-5.1$ ceph osd crush add-bucket raspberry-pi-row1 row

bash-5.1$ ceph osd crush move raspberry-pi-row1 root=default

bash-5.1$ ceph osd crush move 2025-07 row=raspberry-pi-row1
bash-5.1$ ceph osd crush move 2025-09 row=raspberry-pi-row1
bash-5.1$ ceph osd crush move 2025-11 row=raspberry-pi-row1

bash-5.1$ ceph osd tree
ID  CLASS  WEIGHT   TYPE NAME                  STATUS  REWEIGHT  PRI-AFF
-1         1.04846  root default
-9         1.04846      row raspberry-pi-row1
-5         0.34949          host 2025-07
 1   nvme  0.34949              osd.1              up   1.00000  1.00000
-7         0.34949          host 2025-09
 2   nvme  0.34949              osd.2              up   1.00000  1.00000
-3         0.34949          host 2025-11
 0   nvme  0.34949              osd.0              up   1.00000  1.00000
```

### Dashboard <div id='id34' />

```
oscar.mas@2025-05:~ $ cat rook-ceph-dashboard.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rook-ceph-dashboard
  namespace: rook-ceph
spec:
  ingressClassName: cilium
  rules:
  - host: ceph-dashboard.172.26.0.110.nip.io
    http:
      paths:
      - backend:
          service:
            name: rook-ceph-mgr-dashboard
            port:
              number: 7000
        path: /
        pathType: Prefix
```

Saber el password del Dashboard que viene por defecto:

```
oscar.mas@2025-05:~ $ sudo apt-get update && sudo apt-get install jq -y

oscar.mas@2025-05:~ $ k -n rook-ceph get secret rook-ceph-dashboard-password -o jsonpath="{['data']['password']}" | base64 --decode && echo
&+f4&;\$l[^k7lpug<sN
```
Datos de acceso:

* URL: http://ceph-dashboard.172.26.0.110.nip.io
* USERNAME: admin
* PASSWORD: &+f4&;\$l[^k7lpug<sN

### Creación del pool + SC <div id='id35' />

```
oscar.mas@2025-05:~ $ vim rook-ceph-pool-rbd.yaml
apiVersion: ceph.rook.io/v1
kind: CephBlockPool
metadata:
  name: replicapool
  namespace: rook-ceph
spec:
  failureDomain: host
  replicated:
    size: 3
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  clusterID: rook-ceph
  pool: replicapool
  imageFormat: "2"
  imageFeatures: layering
  csi.storage.k8s.io/provisioner-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/provisioner-secret-namespace: rook-ceph
  csi.storage.k8s.io/controller-expand-secret-name: rook-csi-rbd-provisioner
  csi.storage.k8s.io/controller-expand-secret-namespace: rook-ceph
  csi.storage.k8s.io/node-stage-secret-name: rook-csi-rbd-node
  csi.storage.k8s.io/node-stage-secret-namespace: rook-ceph
  csi.storage.k8s.io/fstype: ext4
allowVolumeExpansion: true
reclaimPolicy: Delete
```

```
oscar.mas@2025-05:~ $ k apply -f rook-ceph-pool-rbd.yaml
```

```
oscar.mas@2025-05:~ $ k -n rook-ceph exec deploy/rook-ceph-tools -it -- bash

bash-5.1$ ceph health detail
HEALTH_OK

bash-5.1$ exit

oscar.mas@2025-05:~ $ k -n rook-ceph get cephblockpool
NAME          PHASE   TYPE         FAILUREDOMAIN   AGE
replicapool   Ready   Replicated   host            3m8s

oscar.mas@2025-05:~ $ k -n rook-ceph get sc
NAME                   PROVISIONER                  RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
local-path (default)   rancher.io/local-path        Delete          WaitForFirstConsumer   false                  42d
rook-ceph-block        rook-ceph.rbd.csi.ceph.com   Delete          Immediate              true                   3m14
```



























## Troubleshooting <div id='id100' />

### Rook Ceph: toolbox <div id='id111' />

Contenedor para poder acceder a la consola de Ceph:

```
oscar.mas@2025-05:~ $ wget https://raw.githubusercontent.com/rook/rook/refs/heads/master/deploy/examples/toolbox.yaml
oscar.mas@2025-05:~ $ k ns rook-ceph
oscar.mas@2025-05:~ $ k apply -f toolbox.yaml
oscar.mas@2025-05:~ $ k -n rook-ceph exec deploy/rook-ceph-tools -it -- bash
```

### Rook Ceph: Recopilación de comandos <div id='id112' />


```
bash-5.1$ ceph -s
```

```
bash-5.1$ ceph osd tree
bash-5.1$ ceph osd df tree
bash-5.1$ ceph osd status
bash-5.1$ ceph osd df
bash-5.1$ ceph osd lspools
bash-5.1$ ceph osd pool get <pool> size
```

### Rook Ceph: no encuentra los OSDs <div id='id113' />

El estado del cluster de Ceph nos da *HEALTH_WARN*

```
oscar.mas@2025-05:~ $ kubectl -n rook-ceph get cephcluster
NAME             DATADIRHOSTPATH   MONCOUNT   AGE   PHASE   MESSAGE                        HEALTH        EXTERNAL   FSID
rook-ceph-nvme   /var/lib/rook     3          52m   Ready   Cluster created successfully   HEALTH_WARN              a4a44952-4dcf-4389-bfa7-745bfa633870
```

En los logs podemos ver el siguiente mensaje:

```
oscar.mas@2025-05:~ $ k logs -f rook-ceph-osd-prepare-2025-09-q7vc7
2025-11-21 18:36:37.930139 I | cephosd: no new devices to configure. returning devices already configured with ceph-volume.
2025-11-21 18:36:37.970876 D | exec: Running command: stdbuf -oL ceph-volume --log-path /tmp/ceph-log lvm list  --format json
2025-11-21 18:36:38.186782 D | cephosd: {}
2025-11-21 18:36:38.186808 I | cephosd: 0 ceph-volume lvm osd devices configured on this node
2025-11-21 18:36:38.186835 D | exec: Running command: stdbuf -oL ceph-volume --log-path /tmp/ceph-log raw list --format json
2025-11-21 18:36:42.378498 D | cephosd: {}
2025-11-21 18:36:42.378524 I | cephosd: 0 ceph-volume raw osd devices configured on this node
2025-11-21 18:36:42.378536 W | cephosd: skipping OSD configuration as no devices matched the storage settings for this node "2025-09"
```

Eliminanos los datos del equipo afectado y reiniciamos el operador, para que vuelva a configurar los OSD's:

```
oscar.mas@2025-09:~ $ sudo sgdisk -zap /dev/nvme0n1p3
oscar.mas@2025-09:~ $ sudo dd if=/dev/zero of=/dev/nvme0n1p3 bs=1M count=100
oscar.mas@2025-09:~ $ sudo wipefs -a -f /dev/nvme0n1p3
```

```
oscar.mas@2025-05:~ $ kubectl scale deployment rook-ceph-operator --replicas=0
oscar.mas@2025-05:~ $ kubectl scale deployment rook-ceph-operator --replicas=1
oscar.mas@2025-05:~ $ kubectl -n rook-ceph get cephcluster
```