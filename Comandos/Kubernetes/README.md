# Comandos de Kubernetes

* [Working daily](#id1)
  * [Saber fecha de caducidad de un certificado de K8s](#id10)
  * [Ver pods muertos](#id11)
  * [Eliminar un pod de manera agresiva](#id12)
  * [Cambiar el NS por defecto en el que estamos trabajando](#id13)
  * [Saber los contenedores que tiene un pod y ver los logs](#id14)
  * [Port Forwarding](#id15)
  * [NS que no se borra](#id16)
  * [Ver un secret](#id17)
  * [Pod para debug](#id18)
  * [Hacer limpieza de pods](#id19)
  * [Ver el estado de los Requests y Limits de nuestro cluster](#id20)
  * [Change SC to default](#id21)
* [Alias](#id999)

## Working daily <div id='id1' />

### Saber fecha de caducidad de un certificado de K8s <div id='id10' />

```
$ cat .kube/config-ilimit-pro-k8s | grep client-certificate-data | awk -F " " '{print $2}'| base64 --decode| openssl x509  -enddate -noout
notAfter=Feb 13 10:30:46 2025 GMT
```

### Ver pods muertos <div id='id11' />

```
kubectl get pods -A | grep -Ev 'Running|Completed'
```

### Eliminar un pod de manera agresiva <div id='id12' />

```
kubectl delete pod --grace-period=0 --force
```

### Cambiar el NS por defecto en el que estamos trabajando <div id='id13' />

```
kubectl config set-context --current --namespace=newdefaultnamespace
```

### Saber los contenedores que tiene un pod y ver los logs <div id='id14' />

```
root@kubespray-aio:~# kubectl get pods
NAME              READY   STATUS    RESTARTS   AGE
cluster-mysql-0   0/2     Pending   0          11m
cluster-mysql-1   0/2     Pending   0          11m

root@kubespray-aio:~# kubectl get pods cluster-mysql-0 -o jsonpath='{.spec.containers[*].name}'
sidecar mysql

root@kubespray-aio:~# kubectl logs -f cluster-mysql-0 -c sidecar
```

### Port Forwarding <div id='id15' />

```
kubectl -n wordpress port-forward --address 0.0.0.0 service/wordpress 2222:22
```

### NS que no se borra <div id='id16' />

```
root@ilimit-paas-k8s-test-cp01:~# kubectl delete ns argocd
namespace "argocd" deleted

root@ilimit-paas-k8s-test-cp01:~# kubectl get ns
NAME               STATUS        AGE
argocd             Terminating   2d5h
calico-apiserver   Active        35m
ceph-csi-cephfs    Active        2d5h
```

```
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

### Ver un secret <div id='id17' />

```
root@ilimit-paas-k8s-test2-cp01:~# kubectl -n ceph-csi-rbd describe secrets csi-rbd-secret
Name:         csi-rbd-secret
Namespace:    ceph-csi-rbd
Labels:       app=ceph-csi-rbd
              app.kubernetes.io/managed-by=Helm
              chart=ceph-csi-rbd-3.11.0
              heritage=Helm
              release=ceph-csi-rbd
Annotations:  meta.helm.sh/release-name: ceph-csi-rbd
              meta.helm.sh/release-namespace: ceph-csi-rbd

Type:  Opaque

Data
====
encryptionPassphrase:  15 bytes
userID:                15 bytes
userKey:               40 bytes
```

```
root@ilimit-paas-k8s-test2-cp01:~# kubectl -n ceph-csi-rbd get secret csi-rbd-secret -o json | jq '.data | map_values(@base64d)'
{
  "encryptionPassphrase": "test_passphrase",
  "userID": "ilimit-paas-k8s",
  "userKey": "AQAqUAFmIzO9KxAAODxZC68xLN7n/cRLd8W3DA=="
}
```

---

### Pod para debug <div id='id18' />

```
$ kubectl -n default run debug -it --image=debian
root@debug:/# apt-get update && apt install -y iputils-ping net-tools dnsutils curl telnet nmap
```

### Hacer limpieza de pods <div id='id19' />

```
$ kubectl delete pod -A --field-selector=status.phase==Succeeded
$ kubectl delete pod -A --field-selector=status.phase==Failed
```

### Ver el estado de los Requests y Limits de nuestro cluster  <div id='id20' />

```
$ clear && kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {}; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo'

ilimit-k8s-pro-master01
  Resource           Requests        Limits
  cpu                920m (65%)      300m (21%)
  memory             221286400 (6%)  1024288k (32%)

ilimit-k8s-pro-worker01
  Resource           Requests          Limits
  cpu                3355m (45%)       4650m (62%)
  memory             10084954Ki (65%)  14760781056 (93%)

ilimit-k8s-pro-worker02
  Resource           Requests         Limits
  cpu                4792m (64%)      4500m (60%)
  memory             7329334Ki (47%)  12869002496 (81%)

ilimit-k8s-pro-worker03
  Resource           Requests         Limits
  cpu                1512m (20%)      3253m (43%)
  memory             3710518Ki (23%)  8670504192 (54%)
```

### Change SC to default <div id='id21' />

```
root@kubespray-aio:~# kubectl get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   4m48s

root@kubespray-aio:~# kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

root@kubespray-aio:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   4m59s
```

## Alias <div id='id999' />

Alias básicos:

```
alias k='kubectl'
alias kcdf='kubectl delete -f'
alias kcaf='kubectl apply -f'
alias kcdp='kubectl delete pod --grace-period=0 --force'
```

Todos los alias, los mpuedes encontrar [aquí](https://github.com/ahmetb/kubectl-aliases/blob/master/.kubectl_aliases)
