# Indice


* [Instalación de K8s](#id10)
* [Actualización de K8s](#id11)
* [Dudas](#id20) 
* [Errores](#id30) 
  * [Kubelet client certificate rotation fails](#id31)

# Instalación de K8s <div id='id10' />

Pasos a seguir

* make pre_install
* make install_kubespray ENV=k8s-test KUBE_VERSION=v1.30.4
* make post_install
* make install_applications

# Actualización de K8s <div id='id10' />

Pasos a seguir:

* kubectl drain --ignore-daemonsets --delete-emptydir-data nombre_nodo
* kubectl get nodes -o wide
* make upgrade_kubespray ENV=k8s-test KUBE_VERSION=v1.30.4 NODE=nombre_nodo
* ssh nombre_nodo
* apt-get update && apt-get -y upgrade && apt-get dist-upgrade -y && apt-get -y autoremove && apt-get autoclean && apt-get clean && fstrim --fstab --verbose && reboot
* kubectl get nodes -o wide
* kubectl uncordon nombre_nodo

# Dudas <div id='id20' />

Saber la versión de K8s que podemos instalar
```
$ make shell
root@kubespray:/kubespray# apt-get update && apt-get install less
root@kubespray:/kubespray# less roles/kubespray-defaults/defaults/main/checksums.yml
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

