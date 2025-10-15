* [Instalación de Kubernetes (K3S)](#id10)
  * [Control Plane](#id11)
  * [Worker](#id12)

# Instalación de Kubernetes (K3S) <div id='id10' />


## Control Plane <div id='id11' />

### Install K3s

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
mkdir -p $HOME/.kube
sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
source $HOME/.bashrc
```

### Alias bash

```
k
kcaf
kcdf
kcdp
```

### Install Helm

```
apt-get install
```

### Install Cilium

```
scp values
install cilium
k get nodes
```

## Worker <div id='id12' />

```
sudo cat /var/lib/rancher/k3s/server/token
```

```
k get nodes
```

```
K3S_TOKEN=<TOKEN>
API_SERVER_IP=<IP>
API_SERVER_PORT=<PORT>
curl -sfL https://get.k3s.io | sh -s - agent \
--token "${K3S_TOKEN}" \
--server "https://${API_SERVER_IP}:${API_SERVER_PORT}"
```

```
k get nodes
```