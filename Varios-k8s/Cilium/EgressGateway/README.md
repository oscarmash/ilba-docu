# Index Cilium Egress Gateway:

* [Prerequisites](#id10)
* [Configuración](#id20)
  * [Funcionamiento standard](#id21)

# Prerequisites <div id='id10' />

Partimos de la base de un cluster de Kubernetes montado con el networking de Cilium:

```
root@k8s-cilium-01-cp:~# kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
k8s-cilium-01-cp     Ready    control-plane   5d    v1.30.4
k8s-cilium-01-wk01   Ready    <none>          5d    v1.30.4

root@k8s-cilium-01-cp:~# helm ls -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
cilium          kube-system     1               2024-12-29 10:45:00.265086756 +0100 CET deployed        cilium-1.16.5           1.16.5
```

# Configuración <div id='id20' />

## Despliegue de pod de testing <div id='id21' />

```
root@k8s-cilium-01-cp:~# vim test-EgressGateway-deployment.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: test-egress-gateway
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test-egress-gateway-deployment
  namespace: test-egress-gateway
  labels:
    app.kubernetes.io/name: app-ilba
spec:
  replicas: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: app-ilba
  template:
    metadata:
      labels:
        app.kubernetes.io/name: app-ilba
    spec:
      containers:
        - name: egress-gateway
          image: debian:12
          command:
            - "sleep"
            - "604800"
          imagePullPolicy: IfNotPresent
```

```
root@k8s-cilium-01-cp:~# kubectl apply -f test-EgressGateway-deployment.yaml

root@k8s-cilium-01-cp:~# kubectl -n test-egress-gateway get pods
NAME                                              READY   STATUS    RESTARTS   AGE
test-egress-gateway-deployment-5d6cb584cb-lqqn7   1/1     Running   0          2s
```

## Funcionamiento standard <div id='id22' />

Nos meteremos dentro del pod que hemos creado anteriormente, para ver que la IP que recibe el servidor de mldonkey (172.26.0.68), es la IP del Worker de kubernetes (172.26.0.142)

```
root@k8s-cilium-01-cp:~# NAME_POD=`kubectl -n test-egress-gateway get pods | grep test-egress | awk '{print $1}'`
root@k8s-cilium-01-cp:~# kubectl -n test-egress-gateway exec -it $NAME_POD -- bash
root@test-egress-gateway-deployment-5d6cb584cb-lqqn7:/# apt-get update && apt-get install -y telnet
```

```
root@test-egress-gateway-deployment-5d6cb584cb-lqqn7:/# telnet 172.26.0.68 25
Trying 172.26.0.68...
Connected to 172.26.0.68.
Escape character is '^]'.
220 mldonkey.ilba.cat ESMTP Postfix (Ubuntu)
```

```
root@mldonkey:~# tail -f /var/log/mail.log
Jan 11 08:41:04 mldonkey postfix/smtpd[1582]: lost connection after CONNECT from unknown[172.26.0.142]
Jan 11 08:41:04 mldonkey postfix/smtpd[1582]: disconnect from unknown[172.26.0.142] commands=0/0
Jan 11 08:41:06 mldonkey postfix/smtpd[1582]: connect from unknown[172.26.0.142]
```

## Configuración del Egress Gateway <div id='id23' />

Los únicos valores que hemos añadido al values son:

```
egressGateway:
  enabled: false
```

Procedemos a la configuración de WireGuard

```
helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.16.5 \
-f values-cilium.yaml

root@k8s-cilium-01-cp:~# kubectl rollout restart daemonset/cilium -n kube-system
```

## Funcionamiento del Egress Gateway <div id='id24' />

```
root@k8s-cilium-01-cp:~# cat test-EgressGateway.yaml
apiVersion: cilium.io/v2
kind: CiliumEgressGatewayPolicy
metadata:
  name: egress-gateway
  namespace: test-egress-gateway
spec:
  selectors:
  - podSelector:
      matchLabels:
        app.kubernetes.io/name: app-ilba
  destinationCIDRs:
  - "0.0.0.0/0"
  egressGateway:
    nodeSelector:
      matchLabels:
        app.kubernetes.io/name: app-ilba
    egressIP: 172.26.0.111
```

```
root@k8s-cilium-01-cp:~# kubectl apply -f test-EgressGateway.yaml
ciliumegressgatewaypolicy.cilium.io/egress-gateway created
```








Nos meteremos dentro del pod que hemos creado anteriormente, para ver que la IP que recibe el servidor de mldonkey (172.26.0.68), es la IP indicada en el Egress Gateway (172.26.0.111)

```
root@k8s-cilium-01-cp:~# NAME_POD=`kubectl -n test-egress-gateway get pods | grep test-egress | awk '{print $1}'`
root@k8s-cilium-01-cp:~# kubectl -n test-egress-gateway exec -it $NAME_POD -- bash
root@test-egress-gateway-deployment-5d6cb584cb-lqqn7:/# apt-get update && apt-get install -y telnet
```

```
root@test-egress-gateway-deployment-5d6cb584cb-lqqn7:/# telnet 172.26.0.68 25
Trying 172.26.0.68...
Connected to 172.26.0.68.
Escape character is '^]'.
220 mldonkey.ilba.cat ESMTP Postfix (Ubuntu)
```

```
root@mldonkey:~# tail -f /var/log/mail.log
Jan 11 08:41:04 mldonkey postfix/smtpd[1582]: lost connection after CONNECT from unknown[172.26.0.142]
Jan 11 08:41:04 mldonkey postfix/smtpd[1582]: disconnect from unknown[172.26.0.142] commands=0/0
Jan 11 08:41:06 mldonkey postfix/smtpd[1582]: connect from unknown[172.26.0.142]
```