* [Aplicaciones](#id1)
  * [App de test](#id10) (nginx)
  * [Tailscale](#id11)


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

## Tailscale <div id='id11' />

En el tailScale, se le han de dr los permisos de:
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