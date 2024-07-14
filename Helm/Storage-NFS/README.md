## Instalación de NFS

```
root@diba-master:~# helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
root@diba-master:~# helm repo update
```

```
root@diba-master:~# cat values-csi-driver-nfs.yaml
externalSnapshotter:
  enabled: true
storageClass:
  create: true
  name: nfs-csi
  parameters:
    server: 172.26.0.195
    share: /nfsshare/diba
```

```
helm upgrade --install \
csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
--create-namespace \
--namespace csi-driver-nfs \
--version=v4.7.0 \
-f values-csi-driver-nfs.yaml
```

```
root@diba-master:~# helm -n csi-driver-nfs ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
csi-driver-nfs  csi-driver-nfs  1               2024-06-14 07:41:37.30507464 +0200 CEST deployed        csi-driver-nfs-v4.7.0   v4.7.0

root@diba-master:~# kubectl -n csi-driver-nfs get pods
NAME                                   READY   STATUS    RESTARTS      AGE
csi-nfs-controller-65b76f5875-vjr4t    4/4     Running   0             89s
csi-nfs-node-2b5qm                     3/3     Running   0             89s
csi-nfs-node-4v9zn                     3/3     Running   0             89s
csi-nfs-node-xqgjf                     3/3     Running   0             89s
csi-nfs-node-z5bl6                     3/3     Running   0             89s
snapshot-controller-75f486ff8c-7725x   1/1     Running   0             89s

root@diba-master:~# kubectl get sc
NAME      PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-csi   nfs.csi.k8s.io   Delete          Immediate           false                  10m
```

## Testing de NFS

Esto no funciona, porque el contenedor no esta en modo "privileged"

```
root@diba-master:~# kubectl run test-nfs -it --image debian:12 -- bash
root@test-nfs:/# apt update && apt install -y nfs-common

root@test-nfs:/# showmount -e 172.26.0.195
clnt_create: RPC: Unknown host

root@test-nfs:/# mount -t nfs 172.26.0.195:/nfsshare/diba /mnt/
mount.nfs: rpc.statd is not running but is required for remote locking.
mount.nfs: Either use '-o nolock' to keep locks local, or start statd.
mount.nfs: access denied by server while mounting 172.26.0.195:/nfsshare/diba

root@test-nfs:/# mount.nfs4 172.26.0.195:/nfsshare /mnt/
mount.nfs4: access denied by server while mounting 172.26.0.195:/nfsshare

root@test-nfs:/# exit
root@diba-master:~# kubectl delete pod test-nfs
```


```
root@diba-nfs:~# mkdir /nfsshare/diba

root@diba-master:~# cat test-nfs.yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-dynamic-volume-claim
  namespace: default
spec:
  storageClassName: nfs-csi
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 666Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: default
spec:
  containers:
  - name: nginx
    image: nginx
    volumeMounts:
    - name: nfs-server
      mountPath: /usr/share/nginx/html
  volumes:
  - name: nfs-server
    persistentVolumeClaim:
      claimName: test-dynamic-volume-claim

root@diba-master:~# kubectl apply -f test-nfs.yaml

root@diba-master:~# kubectl exec -it nginx -- df -h | grep diba
172.26.0.195:/nfsshare/diba/pvc-0521856c-a782-4b9a-ab38-ab3063c96780   62G  2.1G   57G   4% /usr/share/nginx/html

root@diba-master:~# kubectl delete -f test-nfs.yaml
```
