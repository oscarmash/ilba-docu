# Index:

* [Instalación de Istio](#id10)
  * [Descargandonos el Binario](#id11) Recomendada
  * [Via HELM](#id12)
    * [CRD's](#id13)
    * [Istio CNI plugin](#id14)
    * [Ingress Gateway](#id15)  
* [Creación de un Ingress](#id20)
  * [Service / Deployment](#id21)
  * [Gateway / VirtualService](#id22)
  * [DestinationRule](#id23)
* [Advanced Traffic Routing](#id30)
  * [Route based on weights](#id31)
  * [Match and route the traffic](#id32)
  * [Redirect the traffic (HTTP 301)](#id33)
  * [Mirror the traffic to another destination](#id34)
  * [AND and OR Semantics](#id35)
* [Service Resiliency & Failure Injection](#id40)
  * [Service Resiliency](#id41)
  * [Circuit Breaking with Outlier Detection](#id42)
  * [Failure Injection](#id41)
* [Jaeger](#id80) FALLA
* [Kiali](#id90) FALLA

# Instalación de Istio <div id='id10' />

## Documentación

Notas importantes de Istio:

* Partimos de un cluster sin Ingress de ningún tipo
* Lo único que hay montado es el MetalLB

## Descargandonos el Binario <div id='id11' />

```
root@kubespray-aio:~# kubectl get nodes
NAME               STATUS   ROLES           AGE    VERSION
kubespray-aio      Ready    control-plane   169d   v1.27.5
kubespray-aio-w1   Ready    <none>          168d   v1.27.5
kubespray-aio-w2   Ready    <none>          168d   v1.27.5

root@kubespray-aio:~# kubectl get ns
NAME              STATUS   AGE
default           Active   169d
kube-node-lease   Active   169d
kube-public       Active   169d
kube-system       Active   169d
metallb-system    Active   169d
```

```
root@kubespray-aio:~# curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.20.3 TARGET_ARCH=x86_64 sh -
root@kubespray-aio:~# cp istio-1.20.3/bin/istioctl /usr/local/bin/istio-1.20.3
root@kubespray-aio:~# ln -s /usr/local/bin/istio-1.20.3 /usr/local/bin/istioctl

root@kubespray-aio:~# istioctl x precheck
✔ No issues found when checking the cluster. Istio is safe to install or upgrade!
  To get started, check out https://istio.io/latest/docs/setup/getting-started/

root@kubespray-aio:~# istioctl install --set profile=demo -y
✔ Istio core installed
✔ Istiod installed
✔ Egress gateways installed
✔ Ingress gateways installed
✔ Installation complete
Made this installation the default for injection and validation.

root@kubespray-aio:~# kubectl -n istio-system get pods
NAME                                    READY   STATUS    RESTARTS   AGE
istio-egressgateway-687cb674fc-59gs9    1/1     Running   0          37s
istio-ingressgateway-85c5875ff7-ctkb9   1/1     Running   0          37s
istiod-7fb4d64fb6-glmdm                 1/1     Running   0          58s

root@kubespray-aio:~# kubectl -n istio-system get svc
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.233.23.70    <none>         80/TCP,443/TCP                                                               45s
istio-ingressgateway   LoadBalancer   10.233.49.152   172.26.0.101   15021:30511/TCP,80:31774/TCP,443:31205/TCP,31400:31367/TCP,15443:31689/TCP   45s
istiod                 ClusterIP      10.233.44.147   <none>         15010/TCP,15012/TCP,443/TCP,15014/TCP                                        66s
```

## Via Helm <div id='id12' />

La instalación de Istio via helm, se compone de los siguientes productos:
* [CRD's](#id13)
* [Istio CNI plugin](#id14)
* [Ingress Gateway](#id15)

### CRD's <div id='id13' />

Istio Base instala los CRDs (Custom Resource Definitions) y los roles de clúster esenciales.

```
root@kubespray-aio:~# helm repo add istio https://istio-release.storage.googleapis.com/charts && helm repo update

root@kubespray-aio:~# helm install istio-base istio/base -n istio-system --set defaultRevision=default --create-namespace

root@kubespray-aio:~# helm -n istio-system ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
istio-base      istio-system    1               2024-07-06 08:38:31.152764741 +0200 CEST        deployed        base-1.22.2     1.22.2
```

### Istio CNI plugin <div id='id14' />

Istio CNI plugin redirige el tráfico de red a los proxies sidecar de Envoy sin requerir el uso de un contenedor init o credenciales elevadas en el pod.

```
root@kubespray-aio:~# helm install istiod istio/istiod -n istio-system --wait

root@kubespray-aio:~# helm -n istio-system ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
istio-base      istio-system    1               2024-07-06 08:38:31.152764741 +0200 CEST        deployed        base-1.22.2     1.22.2
istiod          istio-system    1               2024-07-06 08:39:01.60726576 +0200 CEST         deployed        istiod-1.22.2   1.22.2
```

### Ingress Gateway <div id='id15' />

Se ha ce verificar que tengamos ip's libres antes de instalar el Ingress Gateway:

```
root@k8s-test-cp:~# k -n metallb-system get IPAddressPool
NAME        AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
base-pool   true          false             ["172.26.0.101/32"]

root@k8s-test-cp:~# cat <<EOF > metallb_config.yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: base-pool
  namespace: metallb-system
spec:
  addresses:
  - 172.26.0.101/32
  - 172.26.0.102/32
EOF

root@k8s-test-cp:~# k apply -f metallb_config.yaml

root@k8s-test-cp:~# k -n metallb-system get IPAddressPool
NAME        AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
base-pool   true          false             ["172.26.0.101/32","172.26.0.102/32"]
```

El Ingress Gatewayde Istio sirve como punto de entrada único para el tráfico entrante a un clúster de Kubernetes (es el Ingress):

```
root@kubespray-aio:~# echo "kind: DaemonSet" > values-istio.yaml
root@kubespray-aio:~# helm upgrade --install istio-ingress istio/gateway -n istio-ingress -f values-istio.yaml --create-namespace

root@kubespray-aio:~# kubectl -n istio-ingress get pods -o wide
NAME                  READY   STATUS    RESTARTS   AGE   IP              NODE               NOMINATED NODE   READINESS GATES
istio-ingress-dl8k2   1/1     Running   0          32s   10.233.111.67   kubespray-aio      <none>           <none>
istio-ingress-m2sv5   1/1     Running   0          32s   10.233.109.29   kubespray-aio-w1   <none>           <none>
istio-ingress-xw4jp   1/1     Running   0          32s   10.233.112.20   kubespray-aio-w2   <none>           <none>

root@kubespray-aio:~# helm -n istio-ingress ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
istio-ingress   istio-ingress   1               2024-07-06 08:40:09.378262571 +0200 CEST        deployed        gateway-1.22.2  1.22.2

root@kubespray-aio:~# k -n istio-ingress get svc
NAME            TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                      AGE
istio-ingress   LoadBalancer   10.233.11.105   172.26.0.102   15021:30561/TCP,80:30319/TCP,443:30916/TCP   10m

root@kubespray-aio:~# POD=`kubectl -n istio-ingress get pods | grep istio-ingress | awk '{print $1}' | tail -1`
root@kubespray-aio:~# kubectl -n istio-ingress logs -f $POD
....
2024-07-06T06:40:42.055182Z     info    Readiness succeeded in 1.110894429s
2024-07-06T06:40:42.056220Z     info    Envoy proxy is ready
```

# Creación de un Ingress<div id='id20' />

```
root@kubespray-aio:~# cat 01-istio-namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test-ingress-istio
  labels:
    istio-injection: enabled
```

## Service / Deployment<div id='id21' />

```
root@kubespray-aio:~# cat 05-istio-deployment.yaml
apiVersion: v1
kind: Service
metadata:
  name: mi-primer-service
  namespace: test-ingress-istio
  labels:
     app: mi-primer-service
spec:
  type: ClusterIP
  selector:
    app: mi-primer-deployment
  ports:
    - port: 80
      targetPort: 8080
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mi-primer-deployment
  namespace: test-ingress-istio
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
      containers:
      - name: mi-primer-deployment
        image: paulbouwer/hello-kubernetes:1.9
        ports:
        - containerPort: 8080
```

## Gateway / VirtualService<div id='id22' />

Ejemplo de Gateway y VirtualService:

![alt text](images/gateway-virtualservice.png)

```
root@kubespray-aio:~# cat 10-istio-ingress.yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: httpbin-gateway
  namespace: test-ingress-istio
spec:
  selector:
    istio: ingress        # instalación con helm
    #istio: ingressgateway  # instalación con istioctl
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "www.dominio.cat"
---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: httpbin
  namespace: test-ingress-istio
spec:
  hosts:
  - "www.dominio.cat"
  gateways:
  - httpbin-gateway
  http:
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        port:
          number: 80
        host: mi-primer-service
```

```
root@kubespray-aio:~# kubectl apply -f 01-istio-namespace.yaml
root@kubespray-aio:~# kubectl apply -f 05-istio-deployment.yaml
root@kubespray-aio:~# kubectl apply -f 10-istio-ingress.yaml
```

```
root@kubespray-aio:~# kubectl get ns test-ingress-istio --show-labels
NAME                 STATUS   AGE   LABELS
test-ingress-istio   Active   56s   istio-injection=enabled,kubernetes.io/metadata.name=test-ingress-istio

root@kubespray-aio:~# kubectl -n test-ingress-istio get pods
NAME                                    READY   STATUS    RESTARTS   AGE
mi-primer-deployment-5b8f8476fb-f6trr   2/2     Running   0          93s
mi-primer-deployment-5b8f8476fb-zzcf9   2/2     Running   0          93s

root@kubespray-aio:~# POD=`kubectl -n test-ingress-istio get pods | grep mi-primer- | awk '{print $1}' | tail -1`
root@kubespray-aio:~# kubectl get -n test-ingress-istio pods $POD -o jsonpath='{.spec.containers[*].name}' && echo
mi-primer-deployment istio-proxy

root@kubespray-aio:~# kubectl -n istio-system get svc
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP    PORT(S)                                                                      AGE
istio-egressgateway    ClusterIP      10.233.23.70    <none>         80/TCP,443/TCP                                                               13m
istio-ingressgateway   LoadBalancer   10.233.49.152   172.26.0.101   15021:30511/TCP,80:31774/TCP,443:31205/TCP,31400:31367/TCP,15443:31689/TCP   13m
istiod                 ClusterIP      10.233.44.147   <none>         15010/TCP,15012/TCP,443/TCP,15014/TCP                                        14m

root@kubespray-aio:~# kubectl get vs -A
NAMESPACE            NAME      GATEWAYS              HOSTS                 AGE
test-ingress-istio   httpbin   ["httpbin-gateway"]   ["www.dominio.cat"]   4m10s
```

![alt text](images/hello-kubernetes.png)

## DestinationRule <div id='id23' />

![alt text](images/DestinationRule.png)

[Aquí](https://istio.io/latest/docs/reference/config/networking/destination-rule/)  podremos ver varios ejemplos, pero dejo uno:

```
apiVersion: networking.istio.io/v1
kind: DestinationRule
metadata:
  name: bookinfo-ratings-port
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy: # Apply to all ports
    portLevelSettings:
    - port:
        number: 80
      loadBalancer:
        simple: LEAST_REQUEST
    - port:
        number: 9080
      loadBalancer:
        simple: ROUND_ROBIN
```

# Advanced Traffic Routing <div id='id30' />

## Route based on weights <div id='id31' />

```
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
  - customers.default.svc.cluster.local
  http:
  - name: customers-v1-routes
    route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v1
      weight: 70
  - name: customers-v2-routes
    route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v2
      weight: 30
```

## Match and route the traffic <div id='id32' />

```
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
  - customers.default.svc.cluster.local
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*Firefox.*"
    route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v1
  - route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v2
```

## Redirect the traffic (HTTP 301) <div id='id33' />

```
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
  - customers.default.svc.cluster.local
  http:
  - match:
    - uri:
        exact: /api/v1/helloWorld
    redirect:
      uri: /v1/hello
      authority: hello-world.default.svc.cluster.local
```

## Mirror the traffic to another destination <div id='id34' />

```
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: customers-route
spec:
  hosts:
    - customers.default.svc.cluster.local
  http:
  - route:
    - destination:
        host: customers.default.svc.cluster.local
        subset: v1
      weight: 100
    mirror:
      host: customers.default.svc.cluster.local
      subset: v2
    mirrorPercentage:
      value: 100.0
```

## AND and OR Semantics <div id='id35' />

We can either use AND or OR semantics:

```
http:
  - match:
    - uri:
        prefix: /v1
      headers:
        my-header:
          exact: hello
...
```

The above snippet uses the AND semantics. It states that both the URI prefix needs to match /v1 AND the header my-header has to match the value hello. When both conditions are true, the traffic will be routed to the destination.

To use the OR semantic, we can add another match entry, like this:

```
...
http:
  - match:
    - uri:
        prefix: /v1
    ... 
  - match:
    - headers:
        my-header:
          exact: hello
...
```

In the above snippet, the matching will be done on the URI prefix first, and if it matches, the request gets routed to the destination.

If the first match does not evaluate to true, the algorithm moves to the second match field and tries to match the header. If we omit the match field on the route, it will continually evaluate to true.

When using either of the two options, make sure you provide a fallback route if applicable. That way, if traffic doesn’t match any of the conditions, it could still be routed to a “default” route.


# Service Resiliency & Failure Injection <div id='id40' />
## Service Resiliency <div id='id41' />

Resiliency is the ability to provide and maintain an acceptable level of service in the face of faults and challenges to regular operation. It's not about avoiding failures. It's responding to them, so there's no downtime or data loss. The goal of resiliency is to return the service to a fully functioning state after a failure occurs.

A crucial element in making services available is using timeouts and retry policies when making service requests. We can configure both in the VirtualService resource.

```
...
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  retries:
    attempts: 10
    perTryTimeout: 2s
    retryOn: connect-failure,reset
...
```
## Circuit Breaking with Outlier Detection <div id='id42' />

Another pattern for creating resiliency applications is circuit breaking. It allows us to write services to limit the impact of failures, latency spikes, and other network issues.

Outlier detection is an implementation of a circuit breaker, and it’s a form of passive health checking. It’s called passive because Envoy isn’t actively sending any requests to determine the health of the endpoints. Instead, Envoy observes the performance of different pods to determine if they are healthy or not. If the pods are deemed unhealthy, they are removed or ejected from the healthy load balancing pool.

The pods’ health is assessed through consecutive failures, temporal success rate, latency, and so on.

```
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: customers
spec:
  host: customers
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 1
      http:
        http1MaxPendingRequests: 1
        maxRequestsPerConnection: 1
    outlierDetection:
      consecutive5xxErrors: 1
      interval: 1s
      baseEjectionTime: 3m
      maxEjectionPercent: 100
```

## Failure Injection <div id='id43' />

Another feature to help us with service resiliency is fault injection. We can apply the fault injection policies on HTTP traffic and specify one or more faults to inject when forwarding the request to the destination.

There are two types of fault injection. We can delay the requests before forwarding and emulate a slow network or overloaded service, and we can abort the HTTP request and return a specific HTTP error code to the caller. With the abort, we can simulate a faulty upstream service.

Here's an example that aborts HTTP requests and returns HTTP 404, for 30% of incoming requests:

```
- route:
  - destination:
      host: customers.default.svc.cluster.local
      subset: v1
  fault:
    abort:
      percentage:
        value: 30
      httpStatus: 404
```

# Jaeger <div id='id80' />

Instalación de Jaeger

```
root@kubespray-aio:~# kubectl -n istio-system get cm istio -o yaml
apiVersion: v1
data:
  mesh: |-
    accessLogFile: /dev/stdout
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      proxyMetadata: {}
      tracing:
        zipkin:
          address: zipkin.istio-system:9411
          ....

root@kubespray-aio:~# helm repo add jaegertracing https://jaegertracing.github.io/helm-charts && helm repo update

root@kubespray-aio:~# kubectl create ns istio-observability

root@kubespray-aio:~# vim values-jaeger.yaml
collector:
  service:
    zipkin:
      port: 9411
      nodePort:

root@kubespray-aio:~# helm upgrade --install jaeger jaegertracing/jaeger -n istio-observability -f values-jaeger.yaml

root@kubespray-aio:~# helm ls -n istio-observability
NAME            NAMESPACE               REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
jaeger          istio-observability     1               2024-07-06 08:08:19.215108385 +0200 CEST        deployed        jaeger-3.1.0            1.53.0
```

:memo: esperar un rato + o - 10 minutos

```
root@kubespray-aio:~# kubectl -n istio-observability get pods
NAME                                READY   STATUS      RESTARTS       AGE
jaeger-agent-2mhk8                  1/1     Running     0              3m51s
jaeger-agent-xxhs2                  1/1     Running     0              3m51s
jaeger-agent-zv7jh                  1/1     Running     0              3m51s
jaeger-cassandra-0                  1/1     Running     0              3m51s
jaeger-cassandra-1                  0/1     Running     0              95s
jaeger-cassandra-schema-wbjm6       0/1     Completed   0              3m51s
jaeger-collector-78d5d578bd-nt85t   1/1     Running     5 (2m ago)     3m50s
jaeger-query-6b98b9b7d5-zlmfh       2/2     Running     5 (108s ago)   3m50s
```

Testing de acceso:

```
root@kubespray-aio:~# kubectl port-forward svc/jaeger-query 666:80 -n istio-observability --address 0.0.0.0
```

![alt text](images/jaeger-tests-acceso.png)

Se que esto es feo, pero ahora no se como hacerlo de otra forma.

```
root@kubespray-aio:~# kubectl -n istio-observability get svc
NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                                         AGE
...
jaeger-collector   ClusterIP   10.233.2.224   <none>        14250/TCP,14268/TCP,9411/TCP,14269/TCP          7m2s
...

root@kubespray-aio:~# kubectl -n istio-system edit cm istio
apiVersion: v1
data:
  mesh: |-
    defaultConfig:
      discoveryAddress: istiod.istio-system.svc:15012
      tracing:
        zipkin:
          address: jaeger-collector.istio-observability.svc.cluster.local:9411  <----
    defaultProviders:
      metrics:
      - prometheus
```
# Kiali <div id='id90' />

Instalación de Kiali

```
root@kubespray-aio:~# helm repo add kiali https://kiali.org/helm-charts && helm repo update

root@kubespray-aio:~# vim values-kiali.yaml
istio_namespace: "istio-system"
auth:
  strategy: "anonymous"

helm upgrade --install \
--namespace istio-observability \
-f values-kiali.yaml \
kiali-server \
kiali/kiali-server

root@kubespray-aio:~# helm ls -n istio-observability
NAME            NAMESPACE               REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
jaeger          istio-observability     1               2024-07-06 08:08:19.215108385 +0200 CEST        deployed        jaeger-3.1.0            1.53.0
kiali-server    istio-observability     1               2024-07-06 08:19:29.580183939 +0200 CEST        deployed        kiali-server-1.86.2     v1.86.2
```

Testing de acceso:

```
root@kubespray-aio:~# kubectl port-forward svc/kiali 20001:20001 -n istio-observability --address 0.0.0.0
```
