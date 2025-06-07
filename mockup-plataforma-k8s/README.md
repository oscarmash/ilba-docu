# Indice


* [Instalación de K8s](#id10)
* [Actualización de K8s](#id11)
* [Dudas](#id20) 
* [Errores](#id30) 
  * [Kubelet client certificate rotation fails](#id31)
* [Cosas de KubeSpray](#id40)
  * [etcd_events_cluster_setup: true](#id41) :construction: **No probado**
  * [calico_apiserver_enabled: true](#id42)
  * [resolvconf_mode: docker_dns](#id43)
  * [etcd_deployment_type: host](#id44)
  * [dns_etchosts](#id45)
  * [gvisor_enabled: true](#id46)

# Instalación de K8s <div id='id10' />

Pasos a seguir

* make pre_install ENV=k8s-test
* make install_kubespray ENV=k8s-test KUBE_VERSION=1.31.4
* make post_install ENV=k8s-test
* make install_applications ENV=k8s-test

# Actualización de K8s <div id='id10' />

Pasos a seguir:

* kubectl drain --ignore-daemonsets --delete-emptydir-data nombre_nodo
* kubectl get nodes -o wide
* make upgrade_kubespray ENV=k8s-test KUBE_VERSION=1.31.4 NODE=nombre_nodo
* ssh nombre_nodo
* apt-get update && apt-get -y upgrade && apt-get dist-upgrade -y && apt-get -y autoremove && apt-get autoclean && apt-get clean && fstrim --fstab --verbose && reboot
* kubectl get nodes -o wide
* kubectl uncordon nombre_nodo

# Dudas <div id='id20' />

Saber la versión de K8s que podemos instalar
```
$ make shell
root@kubespray:/kubespray# apt-get update && apt-get install less
root@kubespray:/kubespray# less roles/kubespray_defaults/vars/main/checksums.yml
```

---

De la siguiente [web](https://quay.io/repository/kubespray/kubespray?tab=tags&tag=latest), sacamos la versión del: **KUBESPRAY_VERSION**

# Errores <div id='id30' />

Errores que nos hemos ido encontrando:



## Kubelet client certificate rotation fails <div id='id31' />

En el cluster salía el siguiente mensaje:

```
root@debian-cp:~# kubectl get nodes -o wide
NAME           STATUS     ROLES           AGE      VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION   CONTAINER-RUNTIME
debian-cp      Ready      control-plane   2y209d   v1.29.5   172.26.0.33   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-21-amd64   containerd://1.7.16
debian-node1   NotReady   <none>          2y209d   v1.29.5   172.26.0.34   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-21-amd64   containerd://1.7.16
debian-node2   NotReady   <none>          2y209d   v1.29.5   172.26.0.35   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-21-amd64   containerd://1.7.16
debian-node3   Ready      <none>          2y133d   v1.29.5   172.26.0.80   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-21-amd64   containerd://1.7.16
debian-node4   Ready      <none>          481d     v1.29.5   172.26.0.81   <none>        Debian GNU/Linux 12 (bookworm)   6.1.0-21-amd64   containerd://1.7.16
```

Pero todo seveía bien:

```
root@debian-node1:~# systemctl status kubelet
● kubelet.service - Kubernetes Kubelet Server
     Loaded: loaded (/etc/systemd/system/kubelet.service; enabled; preset: enabled)
     Active: activating (auto-restart) (Result: exit-code) since Tue 2024-10-01 11:33:47 CEST; 5s ago
       Docs: https://github.com/GoogleCloudPlatform/kubernetes
    Process: 1893 ExecStart=/usr/local/bin/kubelet $KUBE_LOGTOSTDERR $KUBE_LOG_LEVEL $KUBELET_API_SERVER $KUBELET_ADDRESS $KUBELET_PORT $KUBELET_HOSTNAME $KUBELET_ARGS $DOCKER_SOCKET $KUBELET_NETWORK_PLUGIN $>
   Main PID: 1893 (code=exited, status=1/FAILURE)
        CPU: 134ms

root@debian-cp:~# kubeadm certs check-expiration
CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Oct 01, 2025 09:36 UTC   364d            ca                      no
apiserver                  Oct 01, 2025 09:36 UTC   364d            ca                      no
apiserver-kubelet-client   Oct 01, 2025 09:36 UTC   364d            ca                      no
controller-manager.conf    Oct 01, 2025 09:36 UTC   364d            ca                      no
front-proxy-client         Oct 01, 2025 09:36 UTC   364d            front-proxy-ca          no
scheduler.conf             Oct 01, 2025 09:36 UTC   364d            ca                      no
super-admin.conf           Oct 01, 2025 09:36 UTC   364d            ca                      no

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Mar 03, 2032 12:16 UTC   7y              no
front-proxy-ca          Mar 03, 2032 12:16 UTC   7y              no
```

Excepto en el log:

```
root@debian-node1:~# tail -f /var/log/syslog
2024-10-01T11:34:07.899178+02:00 debian-node1 kubelet[1914]: E1001 11:34:07.899084    1914 bootstrap.go:266] part of the existing bootstrap client certificate in /etc/kubernetes/kubelet.conf is expired: 2024-09-12 09:18:55 +0000 UTC
```

Como hemos hecho para [solucionarlo](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/troubleshooting-kubeadm/#kubelet-client-cert) ? 

```
root@debian-node1:~# rm -rf /etc/kubernetes/kubelet.conf
root@debian-node1:~# rm -rf /var/lib/kubelet/pki/kubelet-client*

root@debian-cp:~# ls -la /etc/kubernetes/pki/ca.key
-rw------- 1 root root 1675 Mar  6  2022 /etc/kubernetes/pki/ca.key

root@debian-cp:~# kubeadm kubeconfig user --org system:nodes --client-name system:node:debian-node1 > kubelet.conf
root@debian-cp:~# scp kubelet.conf 172.26.0.34:/etc/kubernetes/kubelet.conf

root@debian-cp:~# kubectl get nodes
NAME           STATUS                     ROLES           AGE      VERSION
debian-cp      Ready                      control-plane   2y209d   v1.30.4
debian-node1   Ready,SchedulingDisabled   <none>          2y209d   v1.30.4
debian-node2   NotReady                   <none>          2y209d   v1.29.5
debian-node3   Ready                      <none>          2y133d   v1.29.5
debian-node4   Ready                      <none>          481d     v1.29.5
```

# Cosas de KubeSpray <div id='id40' />

Casi toda la documentación la podemos encontrar [aquí](https://kubespray.io/)

## etcd_events_cluster_setup: true <div id='id41' />

Es aconsejable (no lo he hecho nunca) poner los "events" del cluster en otra BBDD que no sea la que usa K8s. Segirá siendo ETCD:

```
etcd_events_cluster_setup: true
```

## calico_apiserver_enabled: true <div id='id42' />

Hacemos que se cree un contenedor para poder trabajar con calico y no tener que ir instalar el "calicoctl"

```
calico_apiserver_enabled: true
```

```
root@ilimit-paas-k8s-provi-cp01:~# kubectl -n calico-apiserver get pods
NAME                               READY   STATUS    RESTARTS   AGE
calico-apiserver-c744cd8bb-6ktwc   1/1     Running   0          2d4h
```

## resolvconf_mode: docker_dns <div id='id43' />

Como gestiona las [DNS](https://kubespray.io/#/docs/advanced/dns-stack?id=resolvconf_mode):

```
resolvconf_mode: docker_dns
```

## etcd_deployment_type: host <div id='id44' />

Como se [instalará la BBDD de ETCD en el cluster](https://kubespray.io/#/docs/operations/etcd?id=deployment-types):

* etcd_deployment_type: host  - esto lo instalará tipo "apt-get"
* etcd_deployment_type: kubeadm - esto lo instala en un ["static pod"](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/)

## dns_etchosts <div id='id45' />

Añadir entradas en los ficheros de ["/etc/hosts"](https://kubespray.io/#/docs/advanced/dns-stack?id=dns_etchosts-coredns) de los equipos:

```
dns_etchosts: |
  10.101.1.16 ilimit-paas-k8s-pre-cp01
  10.101.1.17 ilimit-paas-k8s-pre-nd01 
  10.101.1.18 ilimit-paas-k8s-pre-nd02 
  10.101.1.19 ilimit-paas-k8s-pre-nd03 
```

## gvisor_enabled: true <div id='id46' />

Poco que comentar, instala [gVisor](https://gvisor.dev/)

```
gvisor_enabled: true
```
