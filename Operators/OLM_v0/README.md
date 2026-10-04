# Tabla de Contenidos

* [Prerrequisitos del Clúster](#prerrequisitos-del-clúster)
* [Instalación de OLM (Operator Lifecycle Manager)](#instalación-de-olm-operator-lifecycle-manager)
* [Despliegue del MariaDB Operator](#despliegue-del-mariadb-operator)
* [Despliegue básico con MariaDB](#despliegue-básico-con-mariadb)
* [Actualización del Operador (Update Process)](#actualización-del-operador-update-process)


# Prerrequisitos del Clúster

```
root@k8s-cilium-01-cp:~# k get nodes
NAME                 STATUS   ROLES           AGE   VERSION
k8s-cilium-01-cp     Ready    control-plane   98d   v1.34.5
k8s-cilium-01-wk01   Ready    <none>          98d   v1.34.5
k8s-cilium-01-wk02   Ready    <none>          98d   v1.34.5
k8s-cilium-01-wk03   Ready    <none>          98d   v1.34.5
```

Hemos de tener un cluster de Ceph con Storage, ya que instalaremos el operator de MariaDB:

```
root@k8s-cilium-01-cp:~# k get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   5m
```

# Instalación de OLM (Operator Lifecycle Manager)

Saber la release a instalar: https://github.com/operator-framework/operator-sdk/releases

```
ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
OS=$(uname | awk '{print tolower($0)}')
export OPERATOR_SDK_DL_URL=https://github.com/operator-framework/operator-sdk/releases/download/v1.42.3
curl -LO ${OPERATOR_SDK_DL_URL}/operator-sdk_${OS}_${ARCH}
chmod +x operator-sdk_${OS}_${ARCH} && mv operator-sdk_${OS}_${ARCH} /usr/local/bin/operator-sdk
```

```
root@k8s-cilium-01-cp:~# operator-sdk olm install
root@k8s-cilium-01-cp:~# operator-sdk olm status
```

```
root@k8s-cilium-01-cp:~# k -n olm get pods
NAME                               READY   STATUS    RESTARTS   AGE
catalog-operator-f868c6674-q7wwx   1/1     Running   0          3m25s
olm-operator-9b5df84fc-hc4np       1/1     Running   0          3m26s
operatorhubio-catalog-q24xj        1/1     Running   0          3m12s
packageserver-86cc9554f6-29ctb     1/1     Running   0          3m13s
packageserver-86cc9554f6-z6247     1/1     Running   0          3m13s

root@k8s-cilium-01-cp:~# k -n olm get catalogsource
NAME                    DISPLAY               TYPE   PUBLISHER        AGE
operatorhubio-catalog   Community Operators   grpc   OperatorHub.io   3m55s
```

Listar todo el software disponible

```
root@k8s-cilium-01-cp:~# k get packagemanifests
```

# Despliegue del MariaDB Operator

Listar todas las CSVs históricas disponibles en tu CatalogSource:

```
root@k8s-cilium-01-cp:~# kubectl get packagemanifest mariadb-operator -n olm -o jsonpath='{range .status.channels[*].entries[*]}{.name}{"\n"}{end}' | grep -i 25
mariadb-operator.v25.10.4
mariadb-operator.v25.10.3
mariadb-operator.v25.10.2
mariadb-operator.v25.10.1
mariadb-operator.v25.10.0
mariadb-operator.v25.8.4
mariadb-operator.v25.8.3
mariadb-operator.v25.8.2
mariadb-operator.v25.8.1
mariadb-operator.v25.8.0
mariadb-operator.v0.25.0
```

Qué canales ofrece el paquete

```
root@k8s-cilium-01-cp:~# kubectl -n olm get packagemanifest mariadb-operator -o jsonpath='{.status.channels[*].name}' && echo
alpha
```

```
root@k8s-cilium-01-cp:~# vim subscription-mariadb.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: mariadb-operator-sub
  namespace: operator-mariadb
spec:
  channel: alpha
  name: mariadb-operator
  source: operatorhubio-catalog
  sourceNamespace: olm
  startingCSV: mariadb-operator.v25.8.4
  installPlanApproval: Manual
```

```
root@k8s-cilium-01-cp:~# k create namespace operator-mariadb
root@k8s-cilium-01-cp:~# k apply -f subscription-mariadb.yaml
```

```
root@k8s-cilium-01-cp:~# k get subscription -n operator-mariadb
NAME                   PACKAGE            SOURCE                  CHANNEL
mariadb-operator-sub   mariadb-operator   operatorhubio-catalog   alpha

root@k8s-cilium-01-cp:~# k describe subscription mariadb-operator-sub -n operator-mariadb
```

Para que el operador que está corriendo en el NS operator-mariadb, escuche y gestione instancias creadas en otros namespaces (como test-mariadb), OLM soporta los siguientes modos según lo que permita el operador:

* Modo AllNamespaces (Recomendado para uso global): si dejas "spec:" vacío o no defines targetNamespaces, el operador pasa a vigilar todos los namespaces del clúster.
* Modo MultiNamespace: añades explícitamente los namespaces que quieres que controle:

```
root@k8s-cilium-01-cp:~# vim operator_group-mariadb.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: operator-mariadb-og
  namespace: operator-mariadb
spec:
  targetNamespaces:
  - operator-mariadb
  - test-mariadb

root@k8s-cilium-01-cp:~# k apply -f operator_group-mariadb.yaml
```

**Nota:**  Esperar un par de segundos antes de lanzar el siguiente comando:

```
root@k8s-cilium-01-cp:~# kubectl get installplan -n operator-mariadb
NAME            CSV                        APPROVAL   APPROVED
install-5ndsw   mariadb-operator.v25.8.4   Manual     false
```

```
root@k8s-cilium-01-cp:~# kubectl patch installplan install-5ndsw \
  -n operator-mariadb \
  --type merge \
  -p '{"spec":{"approved":true}}'
```

```
root@k8s-cilium-01-cp:~# kubectl get installplan -n operator-mariadb
NAME            CSV                         APPROVAL   APPROVED
install-mqxn7   mariadb-operator.v25.10.0   Manual     false
install-z7zt2   mariadb-operator.v25.8.4    Manual     true
```

```
root@k8s-cilium-01-cp:~# k get csv -n operator-mariadb
NAME                       DISPLAY            VERSION   REPLACES                   PHASE
mariadb-operator.v25.8.4   MariaDB Operator   25.8.4    mariadb-operator.v25.8.3   Succeeded

root@k8s-cilium-01-cp:~# kubectl get pods -n operator-mariadb
NAME                                                        READY   STATUS    RESTARTS   AGE
mariadb-operator-helm-controller-manager-679b9fc568-jnw99   1/1     Running   0          50s
```

```
root@k8s-cilium-01-cp:~# vim mariadb_operator-mariadb.yaml
apiVersion: helm.mariadb.mmontes.io/v1alpha1
kind: MariadbOperator
metadata:
  name: mariadb-operator
  namespace: operator-mariadb
spec:
  metrics:
    enabled: false
  webhook:
    enabled: false
  controller:
    enabled: true
```

```
root@k8s-cilium-01-cp:~# k apply -f mariadb_operator-mariadb.yaml

root@k8s-cilium-01-cp:~# kubectl get mariadboperators.helm.mariadb.mmontes.io -n operator-mariadb
NAME               AGE
mariadb-operator   57s

root@k8s-cilium-01-cp:~# k get crd | grep mariadb
backups.k8s.mariadb.com                       2026-08-21T15:20:12Z
connections.k8s.mariadb.com                   2026-08-21T15:20:12Z
databases.k8s.mariadb.com                     2026-08-21T15:20:13Z
externalmariadbs.k8s.mariadb.com              2026-08-21T15:20:14Z
grants.k8s.mariadb.com                        2026-08-21T15:20:12Z
mariadboperators.helm.mariadb.mmontes.io      2026-08-21T15:20:12Z
mariadbs.k8s.mariadb.com                      2026-08-21T15:20:15Z
maxscales.k8s.mariadb.com                     2026-08-21T15:20:13Z
physicalbackups.k8s.mariadb.com               2026-08-21T15:20:12Z
restores.k8s.mariadb.com                      2026-08-21T15:20:13Z
sqljobs.k8s.mariadb.com                       2026-08-21T15:20:14Z
users.k8s.mariadb.com                         2026-08-21T15:20:12Z
```

# Despliegue básico con MariaDB

```
root@k8s-cilium-01-cp:~# k create namespace test-mariadb

root@k8s-cilium-01-cp:~# vim mariadb-BBDD.yaml
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-operator-secrets
  namespace: test-mariadb
data:
  MARIADB_ROOT_PASSWORD: c29yaXNhdA==
---
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: mariadb-operator
  namespace: test-mariadb
spec:
  image: mariadb:10.11.3
  database: mariadb-operator-bbdd
  rootPasswordSecretKeyRef:
    name: mariadb-operator-secrets
    key: MARIADB_ROOT_PASSWORD
  updateStrategy:
    type: ReplicasFirstPrimaryLast
  storage:
    size: 5Gi
    resizeInUseVolumes: true
    waitForVolumeResize: true
    storageClassName: csi-rbd-sc
    volumeClaimTemplate:
      accessModes:
      - ReadWriteOnce
      resources:
        requests:
          storage: 5Gi
      storageClassName: csi-rbd-sc

root@k8s-cilium-01-cp:~# k apply -f mariadb-BBDD.yaml
```

```
root@k8s-cilium-01-cp:~# k -n test-mariadb get mariadb
NAME               READY   STATUS    PRIMARY              UPDATES                    AGE
mariadb-operator   True    Running   mariadb-operator-0   ReplicasFirstPrimaryLast   3m25s

root@k8s-cilium-01-cp:~# k -n test-mariadb get pods
NAME                 READY   STATUS    RESTARTS       AGE
mariadb-operator-0   1/1     Running   1 (2m1s ago)   3m35s
```

# Actualización del Operador (Update Process)

Saber la versión que estamos usando actualmente:

```
root@k8s-cilium-01-cp:~# k get csv -n operator-mariadb
NAME                       DISPLAY            VERSION   REPLACES                   PHASE
mariadb-operator.v25.8.4   MariaDB Operator   25.8.4    mariadb-operator.v25.8.3   Succeeded
```

Ver si hay actualizaciones:

```
root@k8s-cilium-01-cp:~# k get installplan -n operator-mariadb
NAME            CSV                         APPROVAL   APPROVED
install-mqxn7   mariadb-operator.v25.10.0   Manual     false
install-z7zt2   mariadb-operator.v25.8.4    Manual     true
```

Aprobamos la actualización:

```
kubectl patch installplan install-mqxn7 \
  -n operator-mariadb \
  --type merge \
  -p '{"spec":{"approved":true}}'

root@k8s-cilium-01-cp:~# k get installplan -n operator-mariadb
NAME            CSV                         APPROVAL   APPROVED
install-mqxn7   mariadb-operator.v25.10.0   Manual     true
install-z7zt2   mariadb-operator.v25.8.4    Manual     true

root@k8s-cilium-01-cp:~# k get csv -n operator-mariadb
NAME                        DISPLAY            VERSION   REPLACES                   PHASE
mariadb-operator.v25.10.0   MariaDB Operator   25.10.0   mariadb-operator.v25.8.4   Installing
mariadb-operator.v25.8.4    MariaDB Operator   25.8.4    mariadb-operator.v25.8.3   Replacing

root@k8s-cilium-01-cp:~# k get csv -n operator-mariadb
NAME                        DISPLAY            VERSION   REPLACES                   PHASE
mariadb-operator.v25.10.0   MariaDB Operator   25.10.0   mariadb-operator.v25.8.4   Succeeded
```