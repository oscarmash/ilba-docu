# Documentación de Ilba

## Básicos

Instalación de K8s con KubeSpray + BootStrap

* [KubeSpray + BootStrap](./mockup-plataforma-k8s/README.md)
* [Imágenes Kubernetes](./Comandos/Imagenes/README.md)

Documentación de comandos de K8S

* [Comandos de Kubernetes](./Comandos/Kubernetes/README.md)
* [Comandos de Helm](./Comandos/Helm/README.md)
* [Comandos de bash](./Comandos/bash/README.md)

## Raspberry PI 5

* [Instalación base](./raspberry-pi/base/README.md)
* [Instalación Kubernetes (K3S)](./raspberry-pi/k8s-k3s/README.md)
* [Aplicaciones](./raspberry-pi/apps/README.md)

## docker-compose

Documentación de productos usando docker-compose

* [HashiCorp Consul](./docker-compose/HashiCorp-Consul/README.md)
* [Ceph all-in-one (AIO)](./docker-compose/Ceph-AIO/README.md)
* [Prometheus Federation](./docker-compose/Prometheus-Federation/README.md)
* [Thanos con Sidecar](./docker-compose/Thanos-Sidecar/README.md)

## Varios sin Kubernetes

* Vault
  * [Ansible con Vault](./Varios-sin-k8s/Ansible-con-Vault/README.md)
  * [Docker-Compose con Vault](./Varios-sin-k8s/Docker-Compose-con-Vault/README.md)

## Helm's

Bootstrap (helms básicos)

* [Helm - Ingress Nginx](./Helm/Ingress-Nginx/README.md)
* [Helm - multiples Ingress Nginx (LAN / DMZ)](./Helm/multiples-lan-dmz-Ingress-Nginx/README.md)

Helms avanzados:

* [Helm - Storage - NFS](./Helm/Storage-NFS/README.md)
* [Helm - Storage - Ceph (RBD)](./Helm/Storage-Ceph-RBD/README.md)
* [Helm - Storage - CephFS](./Helm/Storage-CephFS/README.md)
* [Helm - Promtail / Loki / MinIO](./Helm/Promtail-Loki-MinIO/README.md)
* [Helm - Logs de pods y eventos](./Helm/logs_pods_and_events/README.md)
* [Helm - Kyverno](./Helm/Kyverno/README.md)
* [Helm - Kyverno Rules](./Helm/Kyverno-Rules/README.md)
* [Helm - Zabbix](./Helm/Zabbix/README.md)
* [Helm - Argo CD](./Helm/ArgoCD/README.md)
* [Helm - Argo Rollout](./Helm/ArgoRollout/README.md) :construction: **No acabado**
* [Helm - Vault](./Helm/Vault/README.md) (ExternalSecrets)
* [Helm - Goldilocks](./Helm/Goldilocks/README.md) (Limits and Requests)
* [Helm - cert-managet](./Helm/cert-manager/README.md)

## Operators

Los operators los podemos encontrar aquí:
* https://operatorhub.io/
* https://artifacthub.io/packages/search

Documentación de productos usando Operators

* [Operator - MariaDB](./Operators/MariaDB/README.md)
* [Operator - Prometheus](./Operators/Prometheus/README.md) :construction: **No acabado**
* [Operator - Loki](./Operators/Loki/README.md) :construction: **No acabado**

## Varios Kubernetes

### Varios

* [RBAC](./Varios/RBAC/README.md)
* [Istio](./Varios-k8s/Istio/README.md) (sin eBPF)
* [Velero](./Varios-k8s/Velero/README.md)
* [Ceph - Object Storage](./Varios/Ceph-Object-Storage/README.md) :construction: **No acabado**
* [Ceph - Baja de Ceph RBD + CephFS + Usuarios](./Varios/baja-CephRBD-CephFS-Usuarios/README.md)

### CNI: Calico

* [Calico - Comandos básicos](./Varios-k8s/Calico/Documentation/README.md)
* [Calico - NetworkPolicy](./Varios-k8s/Calico/NetworkPolicy/README.md)

### CNI: Cilium

* [Cilium - Documentación](./Varios-k8s/Cilium/Documentation/README.md)
* [Cilium - Instalación + Cluster Mesh](./Varios-k8s/Cilium/ClusterMesh/README.md)
* [Cilium - Transparent Encryption](./Varios-k8s/Cilium/Transparent-Encryption/README.md)
* [Cilium - Hubble](./Varios-k8s/Cilium/Hubble/README.md)
* [Cilium - Egress Gateway](./Varios-k8s/Cilium/EgressGateway/README.md)
