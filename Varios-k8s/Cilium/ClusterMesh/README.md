# Index:

* [Instalación de K8s con Cilium via KubeSpray](#id10)
  * [Equipos a desplegar](#id11)
  * [Procedimiento de instalación](#id12)
  * [Verificaciones](#id13)
  * [Añadir un host](#id14)


# Instalación de K8s con Cilium via KubeSpray <div id='id10' />

## Equipos a desplegar <div id='id11' />

Los equipos a desplegar son los siguientes:

* Plataforma de Cilium 01
  * CP: k8s-cilium-01-cp -> 172.26.0.141
  * WK: k8s-cilium-01-wk01 -> 172.26.0.142
  * WK: k8s-cilium-01-wk02 -> 172.26.0.143
  * WK: k8s-cilium-01-wk03 -> 172.26.0.144
  * VIP: 172.26.0.101
  * VIP: 172.26.0.102
* Plataforma de Cilium 02
  * CP: k8s-cilium-02-cp -> 172.26.0.145
  * WK: k8s-cilium-02-wk01 -> 172.26.0.146
  * WK: k8s-cilium-02-wk02 -> 172.26.0.147
  * WK: k8s-cilium-02-wk03 -> 172.26.0.148
  * VIP: 172.26.0.105
  * VIP: 172.26.0.106

## Procedimiento de instalación <div id='id12' />

Hemos de instalar kubernetes en la dos plataformas ( pero se instalará sin CNI, ya que [instalaremos Cilium via Helm](./playbooks_custom/install_applications.yaml) )

* Plataforma de Cilium 01
* Plataforma de Cilium 02

Pasos a seguir para la instalción de Kubernetes con Kubespray:

```
$ make pre_install ENV=k8s-cilium-0x
$ make install_kubespray ENV=k8s-cilium-0x
```

```
root@k8s-cilium-01-cp:~# kubectl get nodes
NAME                 STATUS     ROLES           AGE   VERSION
k8s-cilium-01-cp     NotReady   control-plane   24m   v1.30.4
k8s-cilium-01-wk01   NotReady   <none>          23m   v1.30.4
k8s-cilium-01-wk02   NotReady   <none>          23m   v1.30.4
k8s-cilium-01-wk03   NotReady   <none>          23m   v1.30.4
```

```
root@k8s-cilium-01-cp:~# kubectl get nodes k8s-cilium-01-wk02 -o yaml | grep cni
      message:Network plugin returns error: cni plugin not initialized'
```

Datos iportantes a mencionar, que se han usado en los values de los Helms de Cilium desplegados en cada custer (aconsejamos revisar los values.yaml de cada cluster) :
* Se ha cambiado el rango de red de los dos clusters, para que no sean el mismo:
  * En el cluster k8s-cilium-01 el rango es: 10.1.0.0/16
  * En el cluster k8s-cilium-02 el rango es: 10.2.0.0/16
* También el cluster name y el ID, son diferentes en cada cluster
  * Cluster name: k8s-cilium-01 y el id es: 1
  * Cluster name: k8s-cilium-02 y el id es: 2
* Hemos creado los certificados que usará cilium para realizar la conexión de los clusters. No es necesario hacerlo, ya que está hardcodeados en el values de cilium de cada clusters de kubernetes, pero dejo los comandos:

```
$ openssl genrsa -out cilium-ca.key 4096
$ openssl req -x509 -new -nodes -key cilium-ca.key -sha256 -days 3650 -out cilium-ca.crt -subj "/CN=Cilium-CA"
$ cat cilium-ca.crt | base64 | tr -d '\n'
$ cat cilium-ca.key | base64 | tr -d '\n'
```

Instalaremos las aplicaciones dentro del cluster:


```
$ make install_applications ENV=k8s-cilium-0x
```

:warning: Pongo el siguiente comando, por si al instalar Cilium da algún tipo de problema:

```
$ make install_applications_tag ENV=k8s-cilium-0x TAG=cilium_installation
```

## Verificaciones <div id='id13' />

Relizaremos las siguientes verificaciones en los dos clusters:

```
root@k8s-cilium-01-cp:~# kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
k8s-cilium-01-cp     Ready    control-plane   28m   v1.30.4
k8s-cilium-01-wk01   Ready    <none>          28m   v1.30.4

root@k8s-cilium-01-cp:~# helm ls -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
cilium          kube-system     1               2024-12-24 11:08:09.917627681 +0100 CET deployed        cilium-1.16.5           1.16.5
metrics-server  kube-system     1               2024-12-24 11:08:37.677880747 +0100 CET deployed        metrics-server-3.12.2   0.7.2

root@k8s-cilium-01-cp:~# kubectl get pods -A
NAMESPACE      NAME                                       READY   STATUS    RESTARTS        AGE
kube-system    cilium-8gmb9                               1/1     Running   0               81s
kube-system    cilium-envoy-2sr9p                         1/1     Running   0               81s
kube-system    cilium-envoy-sv9gq                         1/1     Running   0               81s
kube-system    cilium-lggxz                               1/1     Running   0               81s
kube-system    cilium-operator-77bf4594ff-5lccq           1/1     Running   0               81s
kube-system    cilium-operator-77bf4594ff-l5bcz           1/1     Running   0               81s
kube-system    coredns-776bb9db5d-kw9cs                   1/1     Running   0               6m43s
kube-system    coredns-776bb9db5d-q4d4t                   1/1     Running   0               30m
kube-system    dns-autoscaler-6ffb84bd6-vmntw             1/1     Running   0               30m
kube-system    kube-apiserver-k8s-cilium-01-cp            1/1     Running   1 (8m56s ago)   32m
kube-system    kube-controller-manager-k8s-cilium-01-cp   1/1     Running   2 (11m ago)     32m
kube-system    kube-scheduler-k8s-cilium-01-cp            1/1     Running   2 (11m ago)     32m
kube-system    metrics-server-869cd9f57-7cspx             1/1     Running   0               55s
kube-system    nginx-proxy-k8s-cilium-01-wk01             1/1     Running   1 (10m ago)     31m
kube-system    nodelocaldns-c45wr                         1/1     Running   1 (11m ago)     30m
kube-system    nodelocaldns-rl4x2                         1/1     Running   1 (10m ago)     30m
test-ingress   app-ilba-deployment-ffd8c6b4b-dq8pn        1/1     Running   0               2m42s
test-ingress   app-ilba-deployment-ffd8c6b4b-st4v2        1/1     Running   0               2m42s

root@k8s-cilium-01-cp:~# kubectl get ippools
NAME        DISABLED   CONFLICTING   IPS AVAILABLE   AGE
pool-ilba   false      False         1               3m1s

root@k8s-cilium-01-cp:~# kubectl get ingress -A
NAMESPACE      NAME               CLASS    HOSTS                   ADDRESS        PORTS   AGE
test-ingress   app-ilba-ingress   cilium   test-ingress.ilba.cat   172.26.0.101   80      3m13s

root@k8s-cilium-01-cp:~# curl -H "Host: test-ingress.ilba.cat" "http://172.26.0.101/"
<!DOCTYPE html>
<html>
<head>
    <title>Hello Kubernetes!</title>
    ...
```

Verificaremos en los dos clusters el estado de cilium:

```
root@k8s-cilium-01-cp:~# cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        OK
```

```
root@k8s-cilium-01-cp:~# cilium clustermesh status
⚠️  Service type NodePort detected! Service may fail when nodes are removed from the cluster!
✅ Service "clustermesh-apiserver" of type "NodePort" found
✅ Cluster access information is available:
  - 172.26.0.141:32379
✅ Deployment clustermesh-apiserver is ready
ℹ️  KVStoreMesh is enabled

✅ All 4 nodes are connected to all clusters [min:1 / avg:1.0 / max:1]
✅ All 1 KVStoreMesh replicas are connected to all clusters [min:1 / avg:1.0 / max:1]

🔌 Cluster Connections:
  - k8s-cilium-02: 4/4 configured, 4/4 connected - KVStoreMesh: 1/1 configured, 1/1 connected
```

## Añadir un host <div id='id14' />

```
$ make add_host ENV=k8s-cilium-0x KUBE_VERSION=vx.xx.x NODE=k8s-cilium-0x-wk0x
```

