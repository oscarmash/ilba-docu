* [Instalación de Kubernetes (K3S)](#id1)
  * [Control Plane](#id10)
    * [Pre instalación K8s](#id11)
    * [Install K3s](#id12)
    * [Tunning bash](#id13)
    * [Install Helm](#id14)
    * [Install Cilium](#id15)
    * [Configuración de IP Pool](#id16)
  * [Worker](#id50)
    * [Pre instalación K8s](#id51)
    * [Instalación de Kubernetes en los nodos/workers](#id52)


# Instalación de Kubernetes (K3S) <div id='id1' />


## Control Plane <div id='id10' />

### Pre instalación K8s <div id='id11' />

```
oscar.mas@2025-05:~ $ sudo systemctl disable systemd-zram-setup@zram0.service
oscar.mas@2025-05:~ $ sudo systemctl mask systemd-zram-setup@zram0.service

oscar.mas@2025-05:~ $ sudo vim /boot/firmware/cmdline.txt
  ... cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1

oscar.mas@2025-05:~ $ sudo reboot
```

### Install K3s <div id='id12' />

Para saber la versión de K3s a instalar: https://docs.k3s.io/release-notes/v1.33.X

```
oscar.mas@2025-05:~ $ sudo bash
root@2025-05:/home/oscar.mas# mkdir -p /etc/rancher/k3s/

$ cat <<EOF > /etc/rancher/k3s/config.yaml
flannel-backend: "none"
disable-kube-proxy: true
disable-network-policy: true
cluster-init: true
disable:
  - servicelb
  - traefik
  - metrics-server
EOF

root@2025-05:/home/oscar.mas# curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.33.5+k3s1 sh -s - --config=/etc/rancher/k3s/config.yaml
```

```
root@2025-05:/home/oscar.mas# systemctl status k3s

root@2025-05:/home/oscar.mas# kubectl get nodes
NAME      STATUS     ROLES                       AGE   VERSION
2025-05   NotReady   control-plane,etcd,master   16s   v1.33.5+k3s1
```

```
root@2025-05:/home/oscar.mas# exit

oscar.mas@2025-05:~ $ mkdir -p $HOME/.kube
oscar.mas@2025-05:~ $ sudo cp -i /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
oscar.mas@2025-05:~ $ sudo chown $(id -u):$(id -g) $HOME/.kube/config
oscar.mas@2025-05:~ $ echo "export KUBECONFIG=$HOME/.kube/config" >> $HOME/.bashrc
oscar.mas@2025-05:~ $ source $HOME/.bashrc

oscar.mas@2025-05:~ $ kubectl get nodes
NAME      STATUS     ROLES                       AGE   VERSION
2025-05   NotReady   control-plane,etcd,master   84s   v1.33.5+k3s1
```

### Tunning bash <div id='id13' />

Alias del sistema:

```
$ cat <<EOF >> .bashrc
### TUNNING K8S
alias k='kubectl'
alias kcdf='kubectl delete -f'
alias kcaf='kubectl apply -f'
alias kcdp='kubectl delete pod --grace-period=0 --force'
### TUNNING K8S
EOF
```

```
oscar.mas@2025-05:~ $ source $HOME/.bashrc
oscar.mas@2025-05:~ $ sudo apt update && sudo apt install -y git
```

Instalar [Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/) y los siguientes plugins:

```
$ kubectl krew install ns
```

### Install Helm <div id='id14' />

```
$ sudo apt-get install -y curl gpg apt-transport-https
$ curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
$ echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
$ sudo apt-get update && sudo apt-get install -y helm
```

### Install Cilium <div id='id15' />

```
$ cd $HOME/ilba/ilba-docu/raspberry-pi/k8s-k3s
$ scp files/values-cilium.yaml oscar.mas@172.26.0.111:
```

```
oscar.mas@2025-05:~ $ helm repo add cilium https://helm.cilium.io/
oscar.mas@2025-05:~ $ helm repo update
oscar.mas@2025-05:~ $ helm search repo cilium/cilium
```

```
oscar.mas@2025-05:~ $ k get nodes
NAME      STATUS     ROLES                       AGE   VERSION
2025-05   NotReady   control-plane,etcd,master   10m   v1.33.5+k3s1
```

:warning: El siguiente paso tarda unos 10 minutos :warning:

```
helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.18.2 \
-f values-cilium.yaml
```

```
oscar.mas@2025-05:~ $ k get nodes
NAME      STATUS   ROLES                       AGE   VERSION
2025-05   Ready    control-plane,etcd,master   23m   v1.33.5+k3s1
```

### Configuración de IP Pool <div id='id16' />

```
$ cd $HOME/ilba/ilba-docu/raspberry-pi/k8s-k3s
$ scp files/cilium-lb-ipam.yaml oscar.mas@172.26.0.111:
```

```
oscar.mas@2025-05:~ $ kcaf cilium-lb-ipam.yaml
```

## Worker <div id='id50' />


### Pre instalación K8s <div id='id51' />

```
oscar.mas@2025-0X:~ $ sudo systemctl disable systemd-zram-setup@zram0.service
oscar.mas@2025-0X:~ $ sudo systemctl mask systemd-zram-setup@zram0.service

oscar.mas@2025-0X:~ $ sudo vim /boot/firmware/cmdline.txt
  ... cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1

oscar.mas@2025-0X:~ $ sudo reboot
```

### Instalación de Kubernetes en los nodos/workers  <div id='id52' />

```
oscar.mas@2025-05:~ $ sudo cat /var/lib/rancher/k3s/server/token
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::server:xxxxxxxxxxxxxx
```

```
oscar.mas@2025-0X:~ $ K3S_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::server:xxxxxxxxxxxxxx
```

:warning: El siguiente paso tarda unos 5 minutos :warning:

```
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=v1.33.5+k3s1 sh -s - agent \
--token "${K3S_TOKEN}" \
--server "https://172.26.0.111:6443"
```

```
oscar.mas@2025-05:~ $ k get nodes
NAME      STATUS   ROLES                       AGE     VERSION
2025-05   Ready    control-plane,etcd,master   37m     v1.33.5+k3s1
2025-07   Ready    <none>                      2m45s   v1.33.5+k3s1
2025-09   Ready    <none>                      113s    v1.33.5+k3s1
```