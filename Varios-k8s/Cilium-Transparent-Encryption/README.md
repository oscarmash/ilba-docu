# Index Cilium Transparent Encryption:

* [Documentación](#id10)
* [Prerequisites](#id20)
* [Cilium with WireGuard](#id20)


# Documentación <div id='id10' />

Notas:
* Kubernetes doesn’t have a native feature to encrypt data in transit inside the cluste
* Cilium supports both IPsec and WireGuard in transparently encrypting traffic between nodes.
* One advantage of WireGuard over IPsec is the fact that each node automatically creates its own encryption key-pair and distributes its public key via the io.cilium.network.wg-pub-key annotation in the Kubernetes CiliumNode custom resource object.

La documnetación de WireGuard Transparent Encryption, la podemos encontrar [aquí](https://docs.cilium.io/en/latest/security/network/encryption-wireguard/)

# Prerequisites <div id='id20' />

Partimos de la base de un cluster de Kubernetes montado con el networking de Cilium:

```
root@k8s-cilium-01-cp:~# kubectl get nodes
NAME                 STATUS   ROLES           AGE   VERSION
k8s-cilium-01-cp     Ready    control-plane   5d    v1.30.4
k8s-cilium-01-wk01   Ready    <none>          5d    v1.30.4

root@k8s-cilium-01-cp:~# helm ls -A
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                   APP VERSION
cilium          kube-system     1               2024-12-29 10:45:00.265086756 +0100 CET deployed        cilium-1.16.5           1.16.5
```

```
root@k8s-cilium-01-cp:~# helm repo add cilium https://helm.cilium.io/
root@k8s-cilium-01-cp:~# helm repo update
```

# Cilium with WireGuard <div id='id30' />

Los únicos valores que hemos añadido al values son:

```
encryption:
  enabled: true
  type: wireguard
```

Procedemos a la configuración de WireGuard

```
helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.16.5 \
-f values-cilium-WireGuard.yaml

root@k8s-cilium-01-cp:~# kubectl rollout restart daemonset/cilium -n kube-system
```

```
root@k8s-cilium-01-cp:~# apt-get update && apt-get install -y jq

root@k8s-cilium-01-cp:~# kubectl get -n kube-system CiliumNode k8s-cilium-01-cp -o json | jq .metadata.annotations
{
  "network.cilium.io/wg-pub-key": "e2/KIyxG3dRS2fHKANMbXfKlauGcM7Ad56WnWGfppAM="
}

root@k8s-cilium-01-cp:~# kubectl exec -n kube-system -ti ds/cilium -- cilium status |grep Encryption
Defaulted container "cilium-agent" out of: cilium-agent, config (init), mount-cgroup (init), apply-sysctl-overwrites (init), mount-bpf-fs (init), clean-cilium-state (init), install-cni-binaries (init)
Encryption:                          Wireguard       [NodeEncryption: Disabled, cilium_wg0 (Pubkey: e2/KIyxG3dRS2fHKANMbXfKlauGcM7Ad56WnWGfppAM=, Port: 51871, Peers: 1)]

root@k8s-cilium-01-cp:~# ifconfig cilium_wg0
cilium_wg0: flags=209<UP,POINTOPOINT,RUNNING,NOARP>  mtu 1420
        unspec 00-00-00-00-00-00-00-00-00-00-00-00-00-00-00-00  txqueuelen 0  (UNSPEC)
        RX packets 217  bytes 66280 (64.7 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 191  bytes 38088 (37.1 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

# Cilium with IPsec <div id='id30' />

Como hemos comentado anteriormente, necesitamos crear el PSK y ponerlo en un secret:

```
root@k8s-cilium-01-cp:~# apt-get update && apt-get install xxd

root@k8s-cilium-01-cp:~# PSK=($(dd if=/dev/urandom count=20 bs=1 2> /dev/null | xxd -p -c 64))

kubectl create -n kube-system secret generic cilium-ipsec-keys \
--from-literal=keys="3 rfc4106(gcm(aes)) $PSK 128"
```

Los únicos valores que hemos añadido al values son:

```
encryption:
  enabled: true
  type: ipsec
```

Procedemos a la configuración de WireGuard

```
helm upgrade --install \
cilium cilium/cilium \
--namespace kube-system \
--version=1.16.5 \
-f values-cilium-IPsec.yaml
```

Instalar la [consola de cilium](https://docs.cilium.io/en/stable/network/clustermesh/clustermesh/#install-the-cilium-cli) en un nodo:

```
root@k8s-cilium-01-cp:~# cilium config view | grep enable-ipsec
enable-ipsec                                      true
```