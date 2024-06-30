# Comandos de Kubernetes

* [Working daily](#id10)
* [Storage](#id20)

## Working daily <div id='id10' />

Eliminar un pod de manera agresiva:

```
kubectl delete pod --grace-period=0 --force
```

Cambiar el NS por defecto en el que estamos trabajando

```
kubectl config set-context --current --namespace=newdefaultnamespace
```

Port Forwarding

```
ilimit-paas-k8s-cp01:~# k -n client-vodafone-wordpress port-forward --address 0.0.0.0 service/vodafone-wordpress-standard-stack-bastion-clients 2222:22
```

## Storage <div id='id20' />

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
