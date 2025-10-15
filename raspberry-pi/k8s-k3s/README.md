* [Instalación de Kubernetes (K3S)](#id10)
  * [Control Plane](#id11)

# Instalación de Kubernetes (K3S) <div id='id10' />


## Control Plane <div id='id11' />

```
# /etc/rancher/k3s/config.yaml
flannel-backend: "none"
disable-kube-proxy: true
disable-network-policy: true
cluster-init: true
disable:
  - servicelb
  - traefik

curl -sfL https://get.k3s.io | sh -s - --config=/etc/rancher/k3s/config.yaml
```

```

```