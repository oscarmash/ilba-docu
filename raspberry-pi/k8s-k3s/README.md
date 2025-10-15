* [Instalación de Kubernetes (K3S)](#id10)
  * [Control Plane](#id11)
  * [Worker](#id12)

# Instalación de Kubernetes (K3S) <div id='id10' />


## Control Plane <div id='id11' />

### Pre instalación K8s

```
$ swapoff -a
$ apt-get remove --purge dphys-swapfile zram-tools
$ vim /etc/fastab (remove swap partition)
```

### Install K3s

```
$ mkdir -p /etc/rancher/k3s/

$ cat <<EOF > /etc/rancher/k3s/config.yaml
flannel-backend: "none"
disable-kube-proxy: true
disable-network-policy: true
cluster-init: true
disable:
  - servicelb
  - traefik
EOF

$ curl -sfL https://get.k3s.io | sh -s - --config=/etc/rancher/k3s/config.yaml
```

```
$ mkdir -p $HOME/.kube
$ sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
$ sudo chown $(id -u):$(id -g) $HOME/.kube/config
$ echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
$ source $HOME/.bashrc
```

```
$ kubectl get nodes
```

### Tunning bash

Alias del sistema:

```
### TUNNING K8S
alias k='kubectl'
alias kcdf='kubectl delete -f'
alias kcaf='kubectl apply -f'
alias kcdp='kubectl delete pod --grace-period=0 --force'
### TUNNING K8S
```

Instalar [Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) y los siguientes plugins:

```
$ kubectl krew install ctx
$ kubectl krew install ns
```

### Install Helm

```
$ sudo apt-get install curl gpg apt-transport-https --yes
$ curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
$ echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
$ sudo apt-get update && sudo apt-get install -y helm
```

### Install Cilium

```
$ scp files/valus-cilium.yaml 172.26.0.111:
```

```
$ helm repo add cilium https://helm.cilium.io/
$ helm repo update
$ helm search repo cilium/cilium
```

```
$ k get nodes
```

```
helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.18.2 \
-f values-cilium.yaml
```

```
$ k get nodes
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