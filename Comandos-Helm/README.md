# Comandos de Helm

* [Varios](#id10)

## Varios <div id='id10' />

Mostrar versiones:

```
root@kubespray-aio:~# helm search repo mariadb-operator/mariadb-operator -l | head -n 5
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
mariadb-operator/mariadb-operator       0.29.0          v0.0.29         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.28.1          v0.0.28         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.28.0          v0.0.28         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.27.0          v0.0.27         Run and operate MariaDB in a cloud native way
```

Mostrar los valores por defecto:

```
root@kubespray-aio:~# helm show values mariadb-operator/mariadb-operator --version 0.29.0 > values-mariadb-operator.yaml
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
