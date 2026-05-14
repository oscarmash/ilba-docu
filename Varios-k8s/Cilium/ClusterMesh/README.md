# Index:

* [Instalación de K8s con Cilium via KubeSpray](#id10)
  * [Equipos a desplegar](#id11)
  * [Procedimiento de instalación](#id12)
  * [Añadir un host](#id13)
  * [Verificaciones](#id14)
* [Setting up Cluster Mesh](#id20)
  * [Prepare the contexts](#id21)
  * [Enable Cluster Mesh](#id22)
  * [Connect the Clusters](#id23)
  * [Test connectivity with commands](#id24)
  * [Test connectivity with x-wing and rebel-base](#id25)

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

```
$ make install_applications ENV=k8s-cilium-0x
```

## Añadir un host <div id='id13' />

```
$ make add_host ENV=k8s-cilium-0x KUBE_VERSION=vx.xx.x NODE=k8s-cilium-0x-wk0x
```

:warning: $ make install_applications_tag ENV=k8s-cilium-0x TAG=cilium_installation

## Verificaciones <div id='id14' />

Relizaremos las siguientes verificaciones:

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

> [!WARNING]  
> Creo que lo siguiente no es necesario

# Setting up Cluster Mesh <div id='id20' />


Instalar la [consola de cilium](https://docs.cilium.io/en/stable/network/clustermesh/clustermesh/#install-the-cilium-cli) en un nodo y verificación del funcionamiento:

```
root@k8s-cilium-01-cp:~# cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 2, Ready: 2/2, Available: 2/2
DaemonSet              cilium-envoy       Desired: 2, Ready: 2/2, Available: 2/2
Deployment             cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
Containers:            cilium             Running: 2
                       cilium-envoy       Running: 2
                       cilium-operator    Running: 2
Cluster Pods:          6/6 managed by Cilium
Helm chart version:    1.16.5
Image versions         cilium             quay.io/cilium/cilium:v1.16.5@sha256:758ca0793f5995bb938a2fa219dcce63dc0b3fa7fc4ce5cc851125281fb7361d: 2
                       cilium-envoy       quay.io/cilium/cilium-envoy:v1.30.8-1733837904-eaae5aca0fb988583e5617170a65ac5aa51c0aa8@sha256:709c08ade3d17d52da4ca2af33f431360ec26268d288d9a6cd1d98acc9a1dced: 2
                       cilium-operator    quay.io/cilium/operator-generic:v1.16.5@sha256:f7884848483bbcd7b1e0ccfd34ba4546f258b460cb4b7e2f06a1bcc96ef88039: 2

```

## Prepare the contexts <div id='id21' />

Preparación de los contextos de kubernetes, para poder gestionar los dos clusters desde un sólo equipo, en este caso hemos usado el equipo "k8s-cilium-01-cp" :

```
root@k8s-cilium-01-cp:~# scp k8s-cilium-02-cp:/root/.kube/config k8s-cilium-02-cp.config

root@k8s-cilium-01-cp:~# sed -i 's/127.0.0.1/172.26.0.145/g' k8s-cilium-02-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/cluster.local/k8s-cilium-02/g' k8s-cilium-02-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/kubernetes-admin/k8s-cilium-02/g' k8s-cilium-02-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/k8s-cilium-02@k8s-cilium-02/k8s-cilium-02/g' k8s-cilium-02-cp.config

root@k8s-cilium-01-cp:~# cp .kube/config k8s-cilium-01-cp.config

root@k8s-cilium-01-cp:~# sed -i 's/127.0.0.1/172.26.0.141/g' k8s-cilium-01-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/cluster.local/k8s-cilium-01/g' k8s-cilium-01-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/kubernetes-admin/k8s-cilium-01/g' k8s-cilium-01-cp.config
root@k8s-cilium-01-cp:~# sed -i 's/k8s-cilium-01@k8s-cilium-01/k8s-cilium-01/g' k8s-cilium-01-cp.config

root@k8s-cilium-01-cp:~# export KUBECONFIG=/root/k8s-cilium-01-cp.config:/root/k8s-cilium-02-cp.config

root@k8s-cilium-01-cp:~# kubectl config get-contexts
CURRENT   NAME            CLUSTER         AUTHINFO        NAMESPACE
*         k8s-cilium-01   k8s-cilium-01   k8s-cilium-01
          k8s-cilium-02   k8s-cilium-02   k8s-cilium-02

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01
root@k8s-cilium-01-cp:~# kubectl get nodes
root@k8s-cilium-01-cp:~# kubectl get svc -A | grep LoadBalancer | awk '{print $5}'
172.26.0.101

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-02
root@k8s-cilium-01-cp:~# kubectl get nodes
root@k8s-cilium-01-cp:~# kubectl get svc -A | grep LoadBalancer | awk '{print $5}'
172.26.0.105

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01
```

## Enable Cluster Mesh <div id='id22' />

Habilitamos el "Cluster Mesh" em cada cluster de kubrernetes

```
root@k8s-cilium-01-cp:~# cilium clustermesh enable --context k8s-cilium-01 --service-type LoadBalancer
root@k8s-cilium-01-cp:~# cilium clustermesh enable --context k8s-cilium-02 --service-type LoadBalancer
```

Verificaciones, conforme se ha habilitado el "cluster mesh":

```
root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01

root@k8s-cilium-01-cp:~# kubectl get svc -A | grep LoadBalancer | awk '{print $5}'
172.26.0.101
172.26.0.102

root@k8s-cilium-01-cp:~# kubectl get pods -A | grep clustermesh-apiserver
kube-system    clustermesh-apiserver-6895dcd575-v2tkv       3/3     Running     0             106s
kube-system    clustermesh-apiserver-generate-certs-p8d48   0/1     Completed   0             105s

root@k8s-cilium-01-cp:~# cilium status

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-02

root@k8s-cilium-01-cp:~# kubectl get svc -A | grep LoadBalancer | awk '{print $5}'
172.26.0.105
172.26.0.106

root@k8s-cilium-01-cp:~# kubectl get pods -A | grep clustermesh-apiserver
kube-system    clustermesh-apiserver-6895dcd575-q8mzb       3/3     Running     0             2m41s
kube-system    clustermesh-apiserver-generate-certs-zw2gd   0/1     Completed   0             2m40s

root@k8s-cilium-01-cp:~# cilium status

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01

root@k8s-cilium-01-cp:~# cilium clustermesh status --context k8s-cilium-01
root@k8s-cilium-01-cp:~# cilium clustermesh status --context k8s-cilium-02
```

## Connect the Clusters <div id='id23' />

Realizamos la conexión de los dos clusters de Kubernetes:

```
root@k8s-cilium-01-cp:~# cilium clustermesh connect --context k8s-cilium-01 --destination-context k8s-cilium-02
✨ Extracting access information of cluster k8s-cilium-01...
🔑 Extracting secrets from cluster k8s-cilium-01...
ℹ️  Found ClusterMesh service IPs: [172.26.0.102]
✨ Extracting access information of cluster k8s-cilium-02...
🔑 Extracting secrets from cluster k8s-cilium-02...
ℹ️  Found ClusterMesh service IPs: [172.26.0.106]
⚠️ Cilium CA certificates do not match between clusters. Multicluster features will be limited!
ℹ️ Configuring Cilium in cluster k8s-cilium-01 to connect to cluster k8s-cilium-02
ℹ️ Configuring Cilium in cluster k8s-cilium-02 to connect to cluster k8s-cilium-01
✅ Connected cluster k8s-cilium-01 <=> k8s-cilium-02!
```

```
root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01
root@k8s-cilium-01-cp:~# kubectl -n kube-system delete pod -l k8s-app=cilium
root@k8s-cilium-01-cp:~# kubectl -n kube-system delete pod -l name=cilium-operator

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-02
root@k8s-cilium-01-cp:~# kubectl -n kube-system delete pod -l k8s-app=cilium
root@k8s-cilium-01-cp:~# kubectl -n kube-system delete pod -l name=cilium-operator

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01
```

## Test connectivity with commands <div id='id24' />

```
root@k8s-cilium-01-cp:~# NAME_POD=`kubectl -n kube-system get pods | grep cilium | head -n 1 | awk '{print $1}'`

root@k8s-cilium-01-cp:~# kubectl -n kube-system exec -ti $NAME_POD -- cilium-dbg status

root@k8s-cilium-01-cp:~# kubectl -n kube-system exec -ti $NAME_POD -- cilium-health status
```

```
root@k8s-cilium-01-cp:~# cilium clustermesh status --context k8s-cilium-01
✅ Service "clustermesh-apiserver" of type "LoadBalancer" found
✅ Cluster access information is available:
  - 172.26.0.102:2379
✅ Deployment clustermesh-apiserver is ready
ℹ️  KVStoreMesh is enabled

✅ All 2 nodes are connected to all clusters [min:1 / avg:1.0 / max:1]
✅ All 1 KVStoreMesh replicas are connected to all clusters [min:1 / avg:1.0 / max:1]

🔌 Cluster Connections:
  - k8s-cilium-02: 2/2 configured, 2/2 connected - KVStoreMesh: 1/1 configured, 1/1 connected

🔀 Global services: [ min:2 / avg:2.0 / max:2 ]
```

```
root@k8s-cilium-01-cp:~# cilium clustermesh status --context k8s-cilium-02
✅ Service "clustermesh-apiserver" of type "LoadBalancer" found
✅ Cluster access information is available:
  - 172.26.0.106:2379
✅ Deployment clustermesh-apiserver is ready
ℹ️  KVStoreMesh is enabled

✅ All 2 nodes are connected to all clusters [min:1 / avg:1.0 / max:1]
✅ All 1 KVStoreMesh replicas are connected to all clusters [min:1 / avg:1.0 / max:1]

🔌 Cluster Connections:
  - k8s-cilium-01: 2/2 configured, 2/2 connected - KVStoreMesh: 1/1 configured, 1/1 connected

🔀 Global services: [ min:2 / avg:2.0 / max:2 ]
```

```
root@k8s-cilium-01-cp:~# NAME_POD=`kubectl -n kube-system get pods | grep cilium | head -n 1 | awk '{print $1}'`

root@k8s-cilium-01-cp:~# kubectl -n kube-system exec -ti $NAME_POD -- cilium node list
```

El siguiente comando **no va a funcionar nunca**, ya que es necesario dos workers para su funcionamiento y sólo hemos desplegado uno:

```
root@k8s-cilium-01-cp:~# cilium connectivity test --context k8s-cilium-01 --multi-cluster k8s-cilium-02
```

## Test connectivity with x-wing and rebel-base <div id='id25' />

El siguiente ejemplo de Star Wars, es un ejemplo sacado de Cilium: https://github.com/cilium/cilium/tree/main/examples/kubernetes/clustermesh

Porque aplicamos el despliegue en los dos clusters, en vez de aplicarlo en uno y que se replique en el otro:
* State from multiple clusters is never mixed. Access from one cluster into another is always read-only. This ensures that the failure domain remains unchanged, i.e. failures in one cluster never propagate into other clusters.

```
root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01
root@k8s-cilium-01-cp:~# kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/examples/kubernetes/clustermesh/cluster1.yaml
root@k8s-cilium-01-cp:~# kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/examples/kubernetes/clustermesh/global-service-example.yaml

root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-02
root@k8s-cilium-01-cp:~# kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/examples/kubernetes/clustermesh/cluster2.yaml
root@k8s-cilium-01-cp:~# kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/refs/heads/main/examples/kubernetes/clustermesh/global-service-example.yaml
```

```
root@k8s-cilium-01-cp:~# kubectl config use-context k8s-cilium-01

root@k8s-cilium-01-cp:~# kubectl get svc
NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes            ClusterIP   10.233.0.1      <none>        443/TCP   44h
rebel-base            ClusterIP   10.233.47.191   <none>        80/TCP    19h
rebel-base-headless   ClusterIP   None            <none>        80/TCP    19h

root@k8s-cilium-01-cp:~# for I in {1..5}; do curl 10.233.47.191 ; done
{"Galaxy": "Alderaan", "Cluster": "Cluster-1"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-1"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-2"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-2"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-1"}
```

```
root@k8s-cilium-02-cp:~# kubectl get svc
NAME                  TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
kubernetes            ClusterIP   10.233.0.1     <none>        443/TCP   44h
rebel-base            ClusterIP   10.233.45.19   <none>        80/TCP    19h
rebel-base-headless   ClusterIP   None           <none>        80/TCP    19h

root@k8s-cilium-02-cp:~# for I in {1..5}; do curl 10.233.45.19 ; done
{"Galaxy": "Alderaan", "Cluster": "Cluster-2"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-1"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-2"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-2"}
{"Galaxy": "Alderaan", "Cluster": "Cluster-1"}
```
