# Instalación de stack de monitorización (logs pods + events)

* [Requisitos previos](#id10)
* [MinIO](#id20)
* [Loki](#id30)
* [Promtail](#id40)
* [KPS](#id50) (Kube Prometheus Stack)
* [KEE](#id60) (Kubernetes Event Exporter)
* [End](#id70)
* [Cosas de Grafana](#id100)
  * [Alta de usuarios](#id101)

## Requisitos previos <div id='id10' />

**Este montaje está pensado para testing, sólo se ha desplegado un pod de cada componente y nunca se ha pensado en la H.A.**

Antes de empezar necesitamos:

* Un cluster de K8S desplegado

```
root@k8s-test-cp:~# kubectl get nodes
NAME            STATUS   ROLES           AGE    VERSION
k8s-test-cp     Ready    control-plane   5d4h   v1.30.4
k8s-test-wk01   Ready    <none>          5d4h   v1.30.4
k8s-test-wk02   Ready    <none>          5d4h   v1.30.4
k8s-test-wk03   Ready    <none>          5d4h   v1.30.4
```

* Un sistema de CSI (en nuestro caso Ceph)

```
root@k8s-test-cp:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   10m
```

Tener un storage de MinIO:

```
root@minio:~# docker ps -a
CONTAINER ID   IMAGE                                      COMMAND                  CREATED         STATUS         PORTS                                                           NAMES
de896f3a2311   minio/minio:RELEASE.2024-06-11T03-13-30Z   "/usr/bin/docker-ent…"   3 minutes ago   Up 3 minutes   0.0.0.0:9000-9001->9000-9001/tcp, :::9000-9001->9000-9001/tcp   minio
```

* Añadir los siguientes repositorios al Helm:

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```

Copiamos los ficheros yaml:

```
scp yaml/* k8s-test-cp:
```

## MinIO <div id='id20' />

Crearemos un bucket en el equipo de MinIO, con el nombre: **k8s-loki**, para alojar los logs:

* URL: [http://172.26.0.35:9001](http://172.26.0.35:9001)
* Username: admin
* Password: superpassword

![alt text](images/creacion_bucket.png)

Seguidamente crearemos el token:

* Access Key: kxPuYaK4DGXPbl3h3JPL
* Secret Key: v8aWAOyRLCRWpznuDZ0O4yNLLCWy4Onb4RMXf3ck

## Loki <div id='id30' />

Antes de desplegar Loki, cambiaremos el token del values, por el que nos ha entregado MinIO e instalaremos Loki.

```
helm upgrade --install \
loki grafana/loki \
--create-namespace \
--namespace loki \
--version=6.24.0 \
-f values-loki.yaml
```

```
root@k8s-test-cp:~# helm -n loki ls
NAME    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
loki    loki            1               2024-12-21 20:14:58.182469537 +0100 CET deployed        loki-6.24.0     3.3.2

root@k8s-test-cp:~# kubectl -n loki get pods
NAME                            READY   STATUS    RESTARTS   AGE
loki-backend-0                  2/2     Running   0          74s
loki-chunks-cache-0             2/2     Running   0          75s
loki-gateway-67c57974cb-f46zk   1/1     Running   0          75s
loki-read-7f6774c7d6-kfb7s      1/1     Running   0          75s
loki-results-cache-0            2/2     Running   0          75s
loki-write-0                    1/1     Running   0          75s
```
## promtail <div id='id40' />

```
helm upgrade --install \
promtail grafana/promtail \
--create-namespace \
--namespace promtail \
--version=6.16.6 \
-f values-promtail.yaml
```

```
root@k8s-test-cp:~# helm -n promtail ls
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
promtail        promtail        1               2024-12-21 20:20:12.463860765 +0100 CET deployed        promtail-6.16.6 3.0.0

root@k8s-test-cp:~# kubectl -n promtail get pods
NAME             READY   STATUS    RESTARTS   AGE
promtail-ftzcz   1/1     Running   0          2m5s
promtail-qb22p   1/1     Running   0          2m5s
promtail-xfv8b   1/1     Running   0          2m5s
promtail-z6gk5   1/1     Running   0          2m5s
```

En estos momentos, MinIO ya tiene que estar recibiendo datos:

![alt text](images/bucket_recibiendo_datos.png)

## KPS <div id='id50' />

```
root@k8s-test-cp:~# kubectl create ns kube-prometheus-stack
```

```
kubectl -n kube-prometheus-stack create secret generic etcd-client-cert \
--from-file=/etc/ssl/etcd/ssl/ca.pem \
--from-file=/etc/ssl/etcd/ssl/node-k8s-test-cp.pem \
--from-file=/etc/ssl/etcd/ssl/node-k8s-test-cp-key.pem
```

```
helm upgrade --install \
kube-prometheus-stack prometheus-community/kube-prometheus-stack  \
--create-namespace \
--namespace kube-prometheus-stack \
--version=67.4.0 \
-f values-kps.yaml
```

Verificaremos el correcto funcionamiento:

```
root@k8s-test-cp:~# helm -n kube-prometheus-stack ls
NAME                    NAMESPACE               REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
kube-prometheus-stack   kube-prometheus-stack   1               2024-12-22 13:29:04.245256595 +0100 CET deployed        kube-prometheus-stack-67.4.0    v0.79.2

root@k8s-test-cp:~# kubectl -n kube-prometheus-stack get pods
NAME                                                        READY   STATUS    RESTARTS   AGE
kube-prometheus-stack-grafana-7799dfd96-mv8kt               3/3     Running   0          74s
kube-prometheus-stack-kube-state-metrics-66488d8b7b-qzwlg   1/1     Running   0          74s
kube-prometheus-stack-operator-7bd64cfd46-sp4kf             1/1     Running   0          74s
kube-prometheus-stack-prometheus-node-exporter-f7hkc        1/1     Running   0          74s
kube-prometheus-stack-prometheus-node-exporter-nhgln        1/1     Running   0          74s
kube-prometheus-stack-prometheus-node-exporter-p2phs        1/1     Running   0          74s
kube-prometheus-stack-prometheus-node-exporter-qqq8m        1/1     Running   0          74s
prometheus-kube-prometheus-stack-prometheus-0               2/2     Running   0          40s
```

```
root@k8s-test-cp:~# kubectl -n kube-prometheus-stack get ingress
NAME                                 CLASS   HOSTS                      ADDRESS        PORTS   AGE
kube-prometheus-stack-alertmanager   nginx   kps-alermanager.ilba.cat   172.26.0.101   80      102s
kube-prometheus-stack-grafana        nginx   kps-grafana.ilba.cat       172.26.0.101   80      102s
kube-prometheus-stack-prometheus     nginx   kps-prometheus.ilba.cat    172.26.0.101   80      102s
```

Verificaremos los accesos:

* Alermanager:
  * URL: [http://kps-alermanager.ilba.cat](http://kps-alermanager.ilba.cat)
* Prometheus:
  * URL: [http://kps-prometheus.ilba.cat](http://kps-alermanager.ilba.cat)
* Grafana:
  * URL: [http://kps-grafana.ilba.cat](http://kps-grafana.ilba.cat)
  * Username: admin
  * Password: superpassword

Aplicaremos el dashboard de Loki:

```
root@k8s-test-cp:~# kubectl apply -f dashboard-loki.yaml
```

![alt text](images/dashboard_loki.png)

## KEE <div id='id60' />

```
helm upgrade --install \
kubernetes-event-exporter oci://registry-1.docker.io/bitnamicharts/kubernetes-event-exporter \
--create-namespace \
--namespace kubernetes-event-exporter \
--version=3.2.14 \
-f values-kubernetes-event-exporter.yaml
```

```
root@k8s-test-cp:~# helm -n kubernetes-event-exporter ls
NAME                            NAMESPACE                       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
kubernetes-event-exporter       kubernetes-event-exporter       1               2024-12-22 13:47:42.969861056 +0100 CET deployed        kubernetes-event-exporter-3.2.14        1.7.0

root@k8s-test-cp:~# kubectl -n kubernetes-event-exporter get pods
NAME                                         READY   STATUS    RESTARTS   AGE
kubernetes-event-exporter-5dfff89bbf-95j9p   1/1     Running   0          41s
```

Aplicaremos el dashboard de Kubernetes Event Exporter:

```
root@k8s-test-cp:~# kubectl apply -f dashboard-kubernetes-event-exporter.yaml
```

![alt text](images/dashboard_kee.png)

## End <div id='id70' />

Al final, podrémos ver lo siguiente:

![alt text](images/end_loki.png)

![alt text](images/end_kee.png)

## Cosas de Grafana <div id='id100' />

### Alta de usuarios <div id='id101' />

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-user-init-script
  namespace: kube-prometheus-stack
data:
  create-user.sh: |
    #!/bin/bash
    echo "Waiting for Grafana to be ready..." 
    until curl -s http://172.26.0.101/api/health -H 'Host:kps-grafana.ilba.cat'; do sleep 5; done

    echo "Creating user..." 
    curl -X POST http://admin:superpassword@172.26.0.101/api/admin/users -H "Content-Type: application/json" -H 'Host:kps-grafana.ilba.cat' -d '{
        "name": "arquitectura",
        "email": "arquitectura@localhost",
        "login": "arquitectura",
        "password": "SuperPassword",
        "role": "User" 
      }'
    curl -X POST http://admin:superpassword@172.26.0.101/api/admin/users -H "Content-Type: application/json" -H 'Host:kps-grafana.ilba.cat' -d '{
        "name": "webmun",
        "email": "webmun@localhost",
        "login": "webmun",
        "password": "SuperPassword",
        "role": "User" 
      }'
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: grafana-create-user
  namespace: kube-prometheus-stack
spec:
  schedule: "*/30 * * * *" 
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: create-user
            image: curlimages/curl:8.13.0
            command: ["/bin/sh", "/scripts/create-user.sh"]
            volumeMounts:
              - name: script-volume
                mountPath: /scripts
          restartPolicy: OnFailure
          volumes:
          - name: script-volume
            configMap:
              name: grafana-user-init-script
              defaultMode: 0755
```