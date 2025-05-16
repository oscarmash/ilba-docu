# Comandos de Kubernetes

* [Working daily](#id1)
  * [Saber fecha de caducidad de un certificado de K8s](#id10)
  * [Ver pods muertos](#id11)
  * [Eliminar un pod de manera agresiva](#id12)
  * [Cambiar el NS por defecto en el que estamos trabajando](#id13)
  * [Saber los contenedores que tiene un pod y ver los logs](#id14)
  * [Port Forwarding](#id15)
  * [NS que no se borra](#id16)
  * [Ver un secret](#id17)
  * [Pod para debug](#id18)
  * [Hacer limpieza de pods](#id19)
  * [Ver el estado de los Requests y Limits](#id20)
  * [Change SC to default](#id21)
  * [Verificaciones ETCD](#id22)
  * [Revisión de certificados](#id23)
  * [Saber rango IP's de cada nodo](#id24)
  * [Curl (testing ingress)](#id25)
  * [Rollout de resources (reinicio de resources)](#id26)
  * [Show resources (limits/resources) by pod](#id27)
* [Alias](#id999)

## Working daily <div id='id1' />

### Saber fecha de caducidad de un certificado de K8s <div id='id10' />

```
$ cat .kube/config-ilimit-pro-k8s | grep client-certificate-data | awk -F " " '{print $2}'| base64 --decode| openssl x509  -enddate -noout
notAfter=Feb 13 10:30:46 2025 GMT
```

### Ver pods muertos <div id='id11' />

```
kubectl get pods -A | grep -Ev 'Running|Completed'
```

### Eliminar un pod de manera agresiva <div id='id12' />

```
kubectl delete pod --grace-period=0 --force nombre_pod
```

### Cambiar el NS por defecto en el que estamos trabajando <div id='id13' />

```
kubectl config set-context --current --namespace=newdefaultnamespace
```

### Saber los contenedores que tiene un pod y ver los logs <div id='id14' />

```
root@kubespray-aio:~# kubectl get pods
NAME              READY   STATUS    RESTARTS   AGE
cluster-mysql-0   0/2     Pending   0          11m
cluster-mysql-1   0/2     Pending   0          11m

root@kubespray-aio:~# kubectl get pods cluster-mysql-0 -o jsonpath='{.spec.containers[*].name}'
sidecar mysql

root@kubespray-aio:~# kubectl logs -f cluster-mysql-0 -c sidecar
```

### Port Forwarding <div id='id15' />

```
kubectl -n wordpress port-forward --address 0.0.0.0 service/wordpress 2222:22
```

### NS que no se borra <div id='id16' />

```
root@ilimit-paas-k8s-test-cp01:~# kubectl delete ns argocd
namespace "argocd" deleted

root@ilimit-paas-k8s-test-cp01:~# kubectl get ns
NAME               STATUS        AGE
argocd             Terminating   2d5h
calico-apiserver   Active        35m
ceph-csi-cephfs    Active        2d5h
```

```
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -
```

### Ver un secret <div id='id17' />

```
root@ilimit-paas-k8s-test2-cp01:~# kubectl -n ceph-csi-rbd describe secrets csi-rbd-secret
Name:         csi-rbd-secret
Namespace:    ceph-csi-rbd
Labels:       app=ceph-csi-rbd
              app.kubernetes.io/managed-by=Helm
              chart=ceph-csi-rbd-3.11.0
              heritage=Helm
              release=ceph-csi-rbd
Annotations:  meta.helm.sh/release-name: ceph-csi-rbd
              meta.helm.sh/release-namespace: ceph-csi-rbd

Type:  Opaque

Data
====
encryptionPassphrase:  15 bytes
userID:                15 bytes
userKey:               40 bytes
```

```
root@ilimit-paas-k8s-test2-cp01:~# kubectl -n ceph-csi-rbd get secret csi-rbd-secret -o json | jq '.data | map_values(@base64d)'
{
  "encryptionPassphrase": "test_passphrase",
  "userID": "ilimit-paas-k8s",
  "userKey": "AQAqUAFmIzO9KxAAODxZC68xLN7n/cRLd8W3DA=="
}
```

### Pod para debug <div id='id18' />

```
$ kubectl -n default run debug -it --image=debian
root@debug:/# apt-get update && apt install -y iputils-ping net-tools dnsutils curl telnet nmap default-mysql-client gpg
```

### Hacer limpieza de pods <div id='id19' />

```
$ kubectl delete pod -A --field-selector=status.phase==Succeeded
$ kubectl delete pod -A --field-selector=status.phase==Failed
```

### Ver el estado de los Requests y Limits <div id='id20' />

A nivel de cluster:

```
$ clear && kubectl get nodes --no-headers | awk '{print $1}' | xargs -I {} sh -c 'echo {}; kubectl describe node {} | grep Allocated -A 5 | grep -ve Event -ve Allocated -ve percent -ve -- ; echo'

ilimit-k8s-pro-master01
  Resource           Requests        Limits
  cpu                920m (65%)      300m (21%)
  memory             221286400 (6%)  1024288k (32%)

ilimit-k8s-pro-worker01
  Resource           Requests          Limits
  cpu                3355m (45%)       4650m (62%)
  memory             10084954Ki (65%)  14760781056 (93%)

ilimit-k8s-pro-worker02
  Resource           Requests         Limits
  cpu                4792m (64%)      4500m (60%)
  memory             7329334Ki (47%)  12869002496 (81%)

ilimit-k8s-pro-worker03
  Resource           Requests         Limits
  cpu                1512m (20%)      3253m (43%)
  memory             3710518Ki (23%)  8670504192 (54%)
```

A nivel de contenedor:

```
root@kubespray-aio:~# kubectl -n kube-system get pods calico-kube-controllers-68485cbf9c-q9g2p -o jsonpath='{range .spec.containers[*]}{"Container Name: "}{.name}{"\n"}{"Requests:"}{.resources.requests}{"\n"}{"Limits:"}{.resources.limits}{"\n"}{end}'

Container Name: calico-kube-controllers
Requests:{"cpu":"30m","memory":"64M"}
Limits:{"cpu":"1","memory":"256M"}
```

```
root@kubespray-aio:~# kubectl top pods -n kube-system calico-kube-controllers-68485cbf9c-q9g2p
NAME                                       CPU(cores)   MEMORY(bytes)
calico-kube-controllers-68485cbf9c-q9g2p   5m           113Mi
```

### Change SC to default <div id='id21' />

```
root@kubespray-aio:~# kubectl get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   4m48s

root@kubespray-aio:~# kubectl patch storageclass csi-rbd-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

root@kubespray-aio:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   4m59s
```

### Verificaciones ETCD  <div id='id22' />

```
[root@su0679 kubernetes]# /usr/local/bin/etcdctl --cacert /etc/ssl/etcd/ssl/ca.pem --cert /etc/ssl/etcd/ssl/node-su0679.pem --key /etc/ssl/etcd/ssl/node-su0679-key.pem  endpoint status -w table --cluster
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|           ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://192.168.160.172:2379 | f370ba11fb781b7d |  3.5.12 |   44 MB |      true |      false |        35 |  199742046 |          199742046 |        |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

```
[root@su0679 kubernetes]# /usr/local/bin/etcdctl --cacert /etc/ssl/etcd/ssl/ca.pem --cert /etc/ssl/etcd/ssl/node-su0679.pem --key /etc/ssl/etcd/ssl/node-su0679-key.pem get /registry --prefix --keys-only | grep -v ^$ | awk -F '/'  '{ h[$3]++ } END {for (k in h) print h[k], k}' | sort -nr
103 secrets
84 clusterroles
72 services
71 clusterrolebindings
69 pods
68 serviceaccounts
66 replicasets
60 controllerrevisions
57 configmaps
....
```

### Revisión de certificados <div id='id23' />

```
ilimit-k8s-pro-master01:~# openssl x509 -enddate -noout -in /etc/ssl/etcd/ssl/ca.pem
notAfter=Jan 25 08:07:02 2122 GMT
ilimit-k8s-pro-master01:~# openssl x509 -enddate -noout -in /etc/ssl/etcd/ssl/node-ilimit-k8s-pro-master01.pem
notAfter=Jan  5 08:06:10 2125 GMT
```

```
ilimit-k8s-pro-master01:~# cat .kube/config | grep client-certificate-data | cut -f2 -d : | tr -d ' ' | base64 -d | openssl x509 -text -out - | grep "Not After"
            Not After : Jan 29 08:08:51 2026 GMT
```

```
ilimit-k8s-pro-master01:~# find /etc/kubernetes/pki/ -type f -name "*.crt" -print|egrep -v 'ca.crt$'|xargs -L 1 -t  -i bash -c 'openssl x509  -noout -text -in {}|grep After'
```

```
ilimit-k8s-pro-master01:~# kubeadm certs check-expiration

CERTIFICATE                EXPIRES                  RESIDUAL TIME   CERTIFICATE AUTHORITY   EXTERNALLY MANAGED
admin.conf                 Feb 18, 2026 15:00 UTC   364d            ca                      no
apiserver                  Feb 18, 2026 15:00 UTC   364d            ca                      no
apiserver-kubelet-client   Feb 18, 2026 15:00 UTC   364d            ca                      no
controller-manager.conf    Feb 18, 2026 15:00 UTC   364d            ca                      no
front-proxy-client         Feb 18, 2026 15:00 UTC   364d            front-proxy-ca          no
scheduler.conf             Feb 18, 2026 15:00 UTC   364d            ca                      no
super-admin.conf           Feb 18, 2026 15:00 UTC   364d            ca                      no

CERTIFICATE AUTHORITY   EXPIRES                  RESIDUAL TIME   EXTERNALLY MANAGED
ca                      Feb 16, 2032 08:08 UTC   6y362d          no
front-proxy-ca          Feb 16, 2032 08:08 UTC   6y362d          no
```

### Saber rango IP's de cada nodo <div id='id24' />

```
root@k8s-cilium-01-cp:~# kubectl get node -o jsonpath='{range .items[*]}{.metadata.name} {.spec.podCIDR}{"\n"}{end}'
k8s-cilium-01-cp 10.233.64.0/24
k8s-cilium-01-wk01 10.233.65.0/24
k8s-cilium-01-wk02 10.233.66.0/24
k8s-cilium-01-wk03 10.233.67.0/24
```

### Curl - Testing ingress <div id='id25' />

```
$ $INGRESS_IP="exmple.com/xx.xx.xx.xx."
$ curl -so /dev/null -w "%{http_code}\n" http://$INGRESS_IP/
```

### Rollout de resources (reinicio de resources) <div id='id26' />

```
$ kubectl rollout restart daemonset/ingress-nginx-private-controller -n ingress-nginx
```

### Show resources (limits/resources) by pod <div id='id27' />

```
$ kubectl describe ResourceQuota
Name:            cb-blas-website-basic-stack-quota
Namespace:       cb-blas-website
Resource         Used    Hard
--------         ----    ----
limits.cpu       16      6
limits.memory    2148Mi  12Gi
requests.cpu     410m    20m
requests.memory  618Mi   256Mi
```

```
$ kubectl get pods --all-namespaces -o custom-columns='NAME:.metadata.name,CPU_REQ:spec.containers[].resources.requests.cpu,CPU_LIM:spec.containers[].resources.limits.cpu,MEMORY_REQ:spec.containers[].resources.requests.memory,MEM_LIM:spec.containers[].resources.limits.memory' | grep -E "NAME|blas"
NAME                                                              CPU_REQ   CPU_LIM   MEMORY_REQ   MEM_LIM
cb-blas-website-basic-stack-adminer-99b5dd44f-rcjh6               50m       1         32Mi         256Mi
cb-blas-website-basic-stack-apache-89f889885-r6fjm                100m      7         128Mi        256Mi
cb-blas-website-basic-stack-php-6b6ddd88c7-6mz5z                  100m      7         128Mi        256Mi
cb-blas-website-bastion-clients-fc4c76944-p982p                   50m       <none>    64Mi         256Mi
cb-blas-website-grafana-deployment-559468657c-g2mn7               100m      <none>    256Mi        1Gi
```


## Alias <div id='id999' />

Alias básicos:

```
alias k='kubectl'
alias kcdf='kubectl delete -f'
alias kcaf='kubectl apply -f'
alias kcdp='kubectl delete pod --grace-period=0 --force'
```

Todos los alias, los mpuedes encontrar [aquí](https://github.com/ahmetb/kubectl-aliases/blob/master/.kubectl_aliases)
