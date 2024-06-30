# Comandos de Helm

* [Varios](#id10)

## Varios <div id='id10' />

Búsquedas

```
root@kubespray-aio:~# helm search repo mysql-operator/mysql-operator
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
mysql-operator/mysql-operator   2.1.3           8.4.0-2.1.3     MySQL Operator Helm Chart for deploying MySQL I...
```

Ver los valores que se ha aplicado en un Helm

```
root@kubespray-aio:~# helm -n ingress-nginx get values ingress-nginx
USER-SUPPLIED VALUES:
controller:
  kind: DaemonSet
  publishService:
    enabled: true
  service:
    externalTrafficPolicy: Local
    type: LoadBalancer
```
