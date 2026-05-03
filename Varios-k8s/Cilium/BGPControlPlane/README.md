# Index BGP Control Plane

* [Documentación](#id10)
* [Router FRR](#id20)
* [Configuración de los CRD's](#id30)
* [Configuración de Kubernetes](#id40)
  * [Conectando Cilium al router FRR](#id41)
  * [Publicar los CIDRs de K8s externamente](#id42)

# Documentación <div id='id10' />

Vamos a pasar, de un sistema de Cilium con BGP totalmente aislado en el cluster de kubernetes, a darle todo el conocimiento a un router FRR basado en debian.

Una de las utilidaes podría ser que para llegar a un Pod desde fuera del clúster, normalmente tendrías que usar un NodePort o un LoadBalancer. Con BGP, el router Debian (FRR) "sabe" dónde están los Pods y se les puede hacer ping directamente a su IP privada

Equipos necesarios:

* Un router FRR basado en Debian
  * 172.26.0.145 frr
* Un cluster de K8s con Cilium:
  * 172.26.0.141 k8s-cilium-01-cp
  * 172.26.0.142 k8s-cilium-01-wk01
  * 172.26.0.143 k8s-cilium-01-wk02
  * 172.26.0.144 k8s-cilium-01-wk03

# Router FRR <div id='id20' />

```
root@frr:~# echo "net.ipv4.ip_forward=1" | tee /etc/sysctl.d/99-ip-forward.conf
root@frr:~# sysctl -p /etc/sysctl.d/99-ip-forward.conf
root@frr:~# apt update && apt install -y frr
```

```
cat <<EOF > /etc/frr/frr.conf
log syslog informational
!
router bgp 64512
 bgp router-id 172.26.0.145
 no bgp default ipv4-unicast

 ! Definimos el grupo para los nodos de Kubernetes
 neighbor K8S-NODES peer-group
 neighbor K8S-NODES remote-as 64512
 neighbor K8S-NODES description Nodos del Cluster Cilium

 ! Listado de tus nodos específicos
 neighbor 172.26.0.141 peer-group K8S-NODES
 neighbor 172.26.0.142 peer-group K8S-NODES
 neighbor 172.26.0.143 peer-group K8S-NODES
 neighbor 172.26.0.144 peer-group K8S-NODES

 address-family ipv4 unicast
  ! Activamos el grupo
  neighbor K8S-NODES activate
  
  ! Configuración de Route Reflector: permite que FRR reenvíe rutas entre los nodos
  neighbor K8S-NODES route-reflector-client
  
  ! Permite que el servidor aprenda múltiples rutas para la misma IP (ECMP)
  maximum-paths 4
 exit-address-family
!
EOF
```

```
root@frr:~# vim /etc/frr/daemons
bgp=yes   # hemos añadido este parámetro
bgpd=yes  # este lo hemos puesto a "yes"
```

```
root@frr:~# systemctl restart frr && systemctl status frr
```

Es normal que en el siguiente comando no veamos nada, ya que no se ha configurado Cilium:

```
root@frr:~# vtysh -c "show ip bgp summary"
Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
172.26.0.141    4      64512         0         0        0    0    0    never       Active        0 N/A
172.26.0.142    4      64512         0         0        0    0    0    never       Active        0 N/A
172.26.0.143    4      64512         0         0        0    0    0    never       Active        0 N/A
172.26.0.144    4      64512         0         0        0    0    0    never       Active        0 N/A
```

# Configuración de los CRD's <div id='id30' />

> [!NOTE]
> Esta parte hay que darle una vuelta, ya que no veo muy claro porque he de desinstalar el helm y volverlo a instalar.

```
root@k8s-cilium-01-cp:~# k get nodes
NAME                 STATUS   ROLES           AGE     VERSION
k8s-cilium-01-cp     Ready    control-plane   2d17h   v1.34.5
k8s-cilium-01-wk01   Ready    <none>          2d17h   v1.34.5
k8s-cilium-01-wk02   Ready    <none>          2d17h   v1.34.5
k8s-cilium-01-wk03   Ready    <none>          2d17h   v1.34.5

root@k8s-cilium-01-cp:~# helm ls -A
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
cilium          kube-system     1               2026-04-30 13:52:09.940578144 +0200 CEST        deployed        cilium-1.16.5           1.16.5

root@k8s-cilium-01-cp:~# cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled
```

Habilitamos los CRD's del [BGP Control Plane](https://docs.cilium.io/en/stable/network/bgp-control-plane/bgp-control-plane-configuration/)

```
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgpadvertisements.yaml
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgpclusterconfigs.yaml
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgpnodeconfigoverrides.yaml
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgpnodeconfigs.yaml
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgppeerconfigs.yaml
kubectl apply -f https://raw.githubusercontent.com/cilium/cilium/v1.16.5/pkg/k8s/apis/cilium.io/client/crds/v2alpha1/ciliumbgppeeringpolicies.yaml
```

```
root@k8s-cilium-01-cp:~# kubectl get crd | grep bgp
ciliumbgpadvertisements.cilium.io            2026-05-03T05:52:01Z
ciliumbgpclusterconfigs.cilium.io            2026-05-03T05:52:00Z
ciliumbgpnodeconfigoverrides.cilium.io       2026-05-03T08:55:22Z
ciliumbgpnodeconfigs.cilium.io               2026-05-03T08:55:22Z
ciliumbgppeerconfigs.cilium.io               2026-05-03T05:52:01Z
ciliumbgppeeringpolicies.cilium.io           2026-05-03T08:55:22Z
```

```
cat <<EOF > values-cilium.yaml
k8sServiceHost: "auto"
k8sServicePort: "auto"
kubeProxyReplacement: "true"
bpf:
  masquerade: true
ipam:
  operator:
    clusterPoolIPv4PodCIDRList: ["10.1.0.0/16"]
ingressController:
  enabled: true
  default: true
  loadbalancerMode: shared
l2announcements:
  enabled: true
cluster:
  name: k8s-cilium-01
  id: 1
bgpControlPlane:
  enabled: true
EOF
```

```
root@k8s-cilium-01-cp:~# helm repo add cilium https://helm.cilium.io/ && helm repo update
root@k8s-cilium-01-cp:~# helm uninstall cilium -n kube-system

helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.16.5 \
-f values-cilium.yaml
```

```
root@k8s-cilium-01-cp:~# watch cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    OK
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled
```

# Configuración de Kubernetes <div id='id40' />

## Conectando Cilium al router FRR <div id='id41' />

Vamos a configurar el BGP Control Plane para que el clúster de Kubernetes "anuncie" automáticamente las rutas de sus Pods, Servicios, etc... el router FRR.

```
cat <<EOF > frr.yaml
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPPeerConfig
metadata:
  name: debian-peer-config
spec:
  ebgpMultihop: 1
---
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPAdvertisement
metadata:
  name: bgp-advertisements
spec:
  advertisements:
    - advertisementType: "Service"
    - advertisementType: "PodCIDR"
---
apiVersion: cilium.io/v2alpha1
kind: CiliumBGPClusterConfig
metadata:
  name: cilium-bgp-cluster
spec:
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
  bgpInstances:
    - name: "instance-64512"
      localASN: 64512
      peers:
        - name: "debian-router"
          peerAddress: "172.26.0.145"
          peerASN: 64512
          peerConfigRef:
            name: "debian-peer-config"
EOF
```

```
root@k8s-cilium-01-cp:~# k apply -f frr.yaml
```

```
root@frr:~# vtysh -c "show ip bgp summary"
Neighbor        V         AS   MsgRcvd   MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd   PfxSnt Desc
172.26.0.141    4      64512         3         4        0    0    0 00:00:36            0        0 GoBGP/3.27.0
172.26.0.142    4      64512         3         4        0    0    0 00:00:35            0        0 GoBGP/3.27.0
172.26.0.143    4      64512         4         5        0    0    0 00:01:01            0        0 GoBGP/3.27.0
172.26.0.144    4      64512         4         5        0    0    0 00:01:00            0        0 GoBGP/3.27.0
```

## Publicar los CIDRs de K8s externamente <div id='id42' />

En este punto, publicaremos las rutas en el equipo FRR (aunque podría ser nuestro desktop), para poder acceder a un pod del cluster como si estuvieramos dentro de la red de K8s

```
root@k8s-cilium-01-cp:~# k run nginx --image=nginx

root@k8s-cilium-01-cp:~# k get pods -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          22s   10.1.2.238   k8s-cilium-01-wk03   <none>           <none>
```

:negative_squared_cross_mark: El ping al pod creado no funciona (como es normal)

```
root@frr:~# ping -c1 10.1.2.238
PING 10.1.2.238 (10.1.2.238) 56(84) bytes of data.
--- 10.1.2.238 ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
```

```
cat <<EOF > cilium-bgp-peering.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
  name: peering-to-frr
spec:
  nodeSelector:
    matchLabels:
      kubernetes.io/os: linux
  virtualRouters:
  - localASN: 64512
    exportPodCIDR: true  # <--- ESTO es lo que anuncia la red de K8s
    neighbors:
    - peerAddress: 172.26.0.145/32
      peerASN: 64512
EOF
```

```
root@k8s-cilium-01-cp:~# k apply -f cilium-bgp-peering.yaml
```

```
root@frr:~# vtysh -c "show ip route bgp"
IPv4 unicast VRF default:
B>* 10.1.0.0/24 [200/0] via 172.26.0.142, ens18, weight 1, 00:00:00
B>* 10.1.2.0/24 [200/0] via 172.26.0.144, ens18, weight 1, 00:00:03
```

:white_check_mark: Al haber publicado los CRD's, ahora nos funcionará el "ping"

```
root@frr:~# ping -c1 10.1.2.238
PING 10.1.2.238 (10.1.2.238) 56(84) bytes of data.
64 bytes from 10.1.2.238: icmp_seq=1 ttl=63 time=1.02 ms
--- 10.1.2.238 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 1.018/1.018/1.018/0.000 ms
```