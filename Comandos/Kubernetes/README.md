# Comandos de Kubernetes

* [Working daily](#id10)
* [Cosas específicas](#id20)
* [Alias](#id30)

## Working daily <div id='id10' />

Ver pods muertos

```
kubectl get pods -A | grep -Ev 'Running|Completed'
```

---

Eliminar un pod de manera agresiva:

```
kubectl delete pod --grace-period=0 --force
```

---

Cambiar el NS por defecto en el que estamos trabajando

```
kubectl config set-context --current --namespace=newdefaultnamespace
```

---

Saber los contenedores que tiene un pod y ver los logs:

```
root@kubespray-aio:~# kubectl get pods
NAME              READY   STATUS    RESTARTS   AGE
cluster-mysql-0   0/2     Pending   0          11m
cluster-mysql-1   0/2     Pending   0          11m

root@kubespray-aio:~# kubectl get pods cluster-mysql-0 -o jsonpath='{.spec.containers[*].name}'
sidecar mysql

root@kubespray-aio:~# kubectl logs -f cluster-mysql-0 -c sidecar
```

---

Port Forwarding

```
kubectl -n wordpress port-forward --address 0.0.0.0 service/wordpress 2222:22
```

---

NS que no se borra:

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

---

Ver un secret:

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

Pod para debug:

```
$ kubectl -n default run debug -it --image=debian
root@debug:/# apt-get update && apt install -y iputils-ping net-tools dnsutils curl
```

## Cosas específicas <div id='id20' />

Change SC to default

```
root@kubespray-aio:~# kubectl get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   4m48s

root@kubespray-aio:~# kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

root@kubespray-aio:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   4m59s
```

## Alias <div id='id30' />

Alias básicos:

```
alias k='kubectl'
alias kcdf='kubectl delete -f'
alias kcaf='kubectl apply -f'
alias kcdp='kubectl delete pod --grace-period=0 --force'
```

Todos los alias, los mpuedes encontrar [aquí](https://github.com/ahmetb/kubectl-aliases/blob/master/.kubectl_aliases)