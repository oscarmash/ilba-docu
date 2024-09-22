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