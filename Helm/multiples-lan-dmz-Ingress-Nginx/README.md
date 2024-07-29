# Index:

* [Prerequisites](#id10)
* [Tag workers](#id20)
* [Install ingress](#id30)
* [MetalLB](#id40)
* [Testing](#id50)
  * [LAN](#id51)
  * [DMZ](#id52)
* [Kyverno](#id60)
* [Kyverno Rules](#id70)

# Prerequisites <div id='id10' />

A falta de una DMZ hemos hecho el montaje todo en la misma red (172.26.0.0/24)

La idea es montar una red en una LAN, con su Ingress y MetalLB y lo mismo de la DMZ


```
                                         Red: LAN                          
                                         +---+                             
                               VIP       |   |  Hostname: kubespray-aio-w1 
                           172.26.0.101  |   |                             
                                         |   |                             
                                         +---+                             
                                                                           
        +---+                                                              
        |   |                                                              
        |   |                                                              
        |   |                                                              
        +---+                                                              
Hostname:kubespray-aio                                                     
Control Plane                             Red: DMZ                         
                                          +---+                            
                                VIP       |   |  Hostname: kubespray-aio-w2
                            172.26.0.102  |   |                            
                                          |   |                            
                                          +---+                            
```

# Tag workers <div id='id20' />

```
root@kubespray-aio:~# kubectl get nodes
NAME               STATUS   ROLES           AGE    VERSION
kubespray-aio      Ready    control-plane   190d   v1.27.5
kubespray-aio-w1   Ready    <none>          189d   v1.27.5
kubespray-aio-w2   Ready    <none>          189d   v1.27.5
```

```
root@kubespray-aio:~# kubectl label --list nodes kubespray-aio-w1
kubernetes.io/hostname=kubespray-aio-w1
kubernetes.io/os=linux
beta.kubernetes.io/arch=amd64
beta.kubernetes.io/os=linux
kubernetes.io/arch=amd64

root@kubespray-aio:~# kubectl label nodes kubespray-aio-w1 workload=lan
root@kubespray-aio:~# kubectl label nodes kubespray-aio-w2 workload=dmz

root@kubespray-aio:~# kubectl label --list nodes kubespray-aio-w1
beta.kubernetes.io/arch=amd64
beta.kubernetes.io/os=linux
kubernetes.io/arch=amd64
kubernetes.io/hostname=kubespray-aio-w1
kubernetes.io/os=linux
workload=lan
```

# Install ingress <div id='id30' />

```
root@kubespray-aio:~# cat lan-values-nginx.yaml
controller:
  service:
    type: LoadBalancer
    externalTrafficPolicy: "Local"
  publishService:
    enabled: true
  kind: DaemonSet
  nodeSelector:
    workload: lan
  ingressClassByName: true
  ingressClass: lan-ingress
  ingressClassResource:
    name: lan-ingress
    controllerValue: k8s.io/lan-ingress
```

```
helm upgrade --install lan-ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace lan-ingress-nginx \
--version=4.9.0 \
-f lan-values-nginx.yaml
```

```
root@kubespray-aio:~# kubectl -n lan-ingress-nginx get pods -o wide
NAME                             READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
ingress-nginx-controller-tdfdz   1/1     Running   0          29s   10.233.109.29   kubespray-aio-w1   <none>           <none>
```

```
root@kubespray-aio:~# cp -a lan-values-nginx.yaml dmz-values-nginx.yaml
root@kubespray-aio:~# sed -i 's/lan/dmz/g' dmz-values-nginx.yaml
root@kubespray-aio:~# cat dmz-values-nginx.yaml

root@kubespray-aio:~# vim dmz-values-nginx.yaml
    ...
    type: LoadBalancer
    ...
```

```
helm upgrade --install dmz-ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace dmz-ingress-nginx \
--version=4.9.0 \
-f dmz-values-nginx.yaml
```

```
root@kubespray-aio:~# kubectl -n dmz-ingress-nginx get pods -o wide
NAME                                 READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
dmz-ingress-nginx-controller-n7v5l   1/1     Running   0          30s   10.233.112.31   kubespray-aio-w2   <none>           <none>
```

```
root@kubespray-aio:~# kubectl get ingressclasses
NAME          CONTROLLER           PARAMETERS   AGE
dmz-ingress   k8s.io/dmz-ingress   <none>       2m6s
lan-ingress   k8s.io/lan-ingress   <none>       3m6s

root@kubespray-aio:~# helm ls -A
NAME                    NAMESPACE               REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
dmz-ingress-nginx       dmz-ingress-nginx       2               2024-07-27 12:20:57.000269245 +0200 CEST        deployed        ingress-nginx-4.9.0     1.9.5
lan-ingress-nginx       lan-ingress-nginx       1               2024-07-27 12:18:12.499699625 +0200 CEST        deployed        ingress-nginx-4.9.0     1.9.5
```

# MetalLB <div id='id40' />

```
helm upgrade --install metallb-system metallb/metallb \
--create-namespace \
--namespace metallb-system \
--version=0.13.12
```

```
root@kubespray-aio:~# cat lan-dmz-crd-ip.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  creationTimestamp: null
  name: lan-ippool
  namespace: metallb-system
spec:
  addresses:
  - 172.26.0.101/32
status: {}
---
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  creationTimestamp: null
  name: dmz-ippool
  namespace: metallb-system
spec:
  addresses:
  - 172.26.0.102/32
status: {}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  creationTimestamp: null
  name: l2advertisement1
  namespace: metallb-system
spec:
  ipAddressPools:
  - lan-ippool
  - dmz-ippool
status: {}

root@kubespray-aio:~# kubectl apply -f lan-dmz-crd-ip.yaml
```

# Testing <div id='id50' />
## LAN <div id='id51' />

```
root@kubespray-aio:~# cat lan-manifest.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: lan-manifest
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-primer-deployment
  namespace: lan-manifest
spec:
  selector:
    matchLabels:
      app: mi-primer-deployment
  replicas: 2
  template:
    metadata:
       labels:
          app: mi-primer-deployment
    spec:
      nodeSelector:
        workload: lan
      containers:
      - name: mi-primer-deployment
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: mi-primer-service
  namespace: lan-manifest
  labels:
     app: mi-primer-service
spec:
  type: ClusterIP
  selector:
    app: mi-primer-deployment
  ports:
    - port: 80
      targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mi-primer-ingress
  namespace: lan-manifest
  annotations:
    metallb.universe.tf/address-pool: lan-ippool
spec:
  ingressClassName: lan-ingress
  rules:
    - host: www.lan.cat
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
               service:
                  name: mi-primer-service
                  port:
                     number: 80
```
```
root@kubespray-aio:~# kubectl apply -f lan-manifest.yaml
```

```
root@kubespray-aio:~# kubectl -n lan-manifest get pods -o wide
NAME                                    READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
mi-primer-deployment-7b9d96c56c-pmh52   1/1     Running   0          30s   10.233.109.35   kubespray-aio-w1   <none>           <none>
mi-primer-deployment-7b9d96c56c-xfk5c   1/1     Running   0          30s   10.233.109.34   kubespray-aio-w1   <none>           <none>

root@kubespray-aio:~# kubectl -n lan-manifest get ingress
NAME                CLASS         HOSTS         ADDRESS        PORTS   AGE
mi-primer-ingress   lan-ingress   www.lan.cat   172.26.0.101   80      46s
```

```
root@kubespray-aio:~# curl -H "Host: www.lan.cat" "http://172.26.0.101/"
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

## DMZ <div id='id52' />

```
root@kubespray-aio:~# cp -a lan-manifest.yaml dmz-manifest.yaml
root@kubespray-aio:~# sed -i 's/lan/dmz/g' dmz-manifest.yaml
root@kubespray-aio:~# kubectl apply -f dmz-manifest.yaml
```
```
root@kubespray-aio:~# kubectl -n dmz-manifest get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
mi-primer-deployment-8b6d774c5-cx8v6   1/1     Running   0          16s   10.233.112.32   kubespray-aio-w2   <none>           <none>
mi-primer-deployment-8b6d774c5-s45tc   1/1     Running   0          16s   10.233.112.33   kubespray-aio-w2   <none>           <none>

root@kubespray-aio:~# kubectl -n dmz-manifest get ingress
NAME                CLASS         HOSTS         ADDRESS        PORTS   AGE
mi-primer-ingress   dmz-ingress   www.dmz.cat   172.26.0.102   80      35s
```

```
root@kubespray-aio:~# kubectl get ingress -A
NAMESPACE      NAME                CLASS         HOSTS         ADDRESS        PORTS   AGE
dmz-manifest   mi-primer-ingress   dmz-ingress   www.dmz.cat   172.26.0.102   80      49s
lan-manifest   mi-primer-ingress   lan-ingress   www.lan.cat   172.26.0.101   80      12m
```

```
root@kubespray-aio:~# curl -H "Host: www.dmz.cat" "http://172.26.0.102/"
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

# Kyverno <div id='id60' />

Instalación de [Kyverno](../../Helm/Kyverno/README.md)

# Kyverno Rules <div id='id70' />

```
root@kubespray-aio:~# kubectl port-forward service/lan-policy-reporter-ui 8082:8080 -n lan-policy-reporter --address 0.0.0.0
```

Policy rules:
* [restrict-ingress-classes.yaml](../..//Helm/Kyverno-Rules/README.md)
* [restrict-address-pool.yaml](../..//Helm/Kyverno-Rules/README.md)
 