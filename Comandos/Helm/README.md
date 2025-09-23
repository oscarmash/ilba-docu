# Comandos de Helm

* [Comandos básicos](#id10)
* [Repositorios](#id20)

## Comandos básicos <div id='id10' />

Instalar un programa con Helm:

```
helm upgrade --install \
ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace ingress-nginx \
--version=4.7.1 \
-f values-nginx.yaml
```

---

Mostrar versiones:

```
root@kubespray-aio:~# helm search repo mariadb-operator/mariadb-operator -l | head -n 5
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
mariadb-operator/mariadb-operator       0.29.0          v0.0.29         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.28.1          v0.0.28         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.28.0          v0.0.28         Run and operate MariaDB in a cloud native way
mariadb-operator/mariadb-operator       0.27.0          v0.0.27         Run and operate MariaDB in a cloud native way
```

---

Mostrar los valores por defecto:

```
root@kubespray-aio:~# helm show values mariadb-operator/mariadb-operator --version 0.29.0 > values-mariadb-operator.yaml
```

---

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

---

Rollout de versiones:

```
$ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
ceph-csi-cephfs ceph-csi-cephfs 4               2025-07-23 12:31:02.290029616 +0200 CEST        deployed        ceph-csi-cephfs-3.14.1  3.14.1

$ helm history ceph-csi-cephfs
REVISION        UPDATED                         STATUS          CHART                   APP VERSION     DESCRIPTION
1               Mon Feb  3 14:31:59 2025        superseded      ceph-csi-cephfs-3.12.2  3.12.2          Install complete
2               Fri Mar 21 12:57:46 2025        superseded      ceph-csi-cephfs-3.12.2  3.12.2          Upgrade complete
3               Tue Apr 29 10:38:57 2025        superseded      ceph-csi-cephfs-3.13.1  3.13.1          Upgrade complete
4               Wed Jul 23 12:31:02 2025        deployed        ceph-csi-cephfs-3.14.1  3.14.1          Upgrade complete

$ helm rollback ceph-csi-cephfs 3

$ helm ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
ceph-csi-cephfs ceph-csi-cephfs 5               2025-07-23 12:48:57.931429897 +0200 CEST        deployed        ceph-csi-cephfs-3.13.1  3.13.1
```

---

Descargar un chart y subirlo a un repositorio:

```
$ helm pull oci://registry-1.docker.io/bitnamicharts/thanos --version=17.2.1

$ ls -lha thanos-17.2.1.tgz
-rw-r--r-- 1 oscar oscar 216K Sep 23 09:40 thanos-17.2.1.tgz

$ helm push thanos-17.2.1.tgz oci://registry.ilimit.es/charts
```

![alt text](images/helm_upload_to_harbor.png
)


## Repositorios <div id='id20' />

Repositorios de Helm, recuerda de hacer un "helm repo update" una vez acabados de añadir los repos

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add metallb https://metallb.github.io/metallb
helm repo add jetstack https://charts.jetstack.io
helm repo add kube-prometheus-stack https://prometheus-community.github.io/helm-charts
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo add external-secrets https://charts.external-secrets.io
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo add policy-reporter https://kyverno.github.io/policy-reporter
helm repo add ceph-csi https://ceph.github.io/csi-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add komodorio https://helm-charts.komodor.io
helm repo add zabbix-chart-6.0 https://cdn.zabbix.com/zabbix/integrations/kubernetes-helm/6.0
helm repo add kasten https://charts.kasten.io/
helm repo add privatebin https://privatebin.github.io/helm-chart
helm repo add doca https://charts.doca.cloud/charts
helm repo add minio https://charts.min.io/
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add gitlab https://charts.gitlab.io
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo add kong https://charts.konghq.com
helm repo add descheduler https://kubernetes-sigs.github.io/descheduler/
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add minio-operator https://operator.min.io
```