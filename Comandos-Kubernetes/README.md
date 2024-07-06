# Comandos de Kubernetes

* [Working daily](#id10)
* [Cosas específicas](#id20)
* [Alias](#id30)

## Working daily <div id='id10' />

Eliminar un pod de manera agresiva:

```
kubectl delete pod --grace-period=0 --force
```

Cambiar el NS por defecto en el que estamos trabajando

```
kubectl config set-context --current --namespace=newdefaultnamespace
```

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

Port Forwarding

```
kubectl -n wordpress port-forward --address 0.0.0.0 service/wordpress 2222:22
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