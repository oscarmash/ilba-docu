# que vamos a hacer:

https://www.cloudkeeper.com/insights/blog/kubernetes-135-understanding-prefersamenode-and-prefersamezone-traffic-distribution

* trafficDistribution:
  * PreferSameNode
  * PreferSameZone

No confundir con: externalTrafficPolicy and internalTrafficPolicy

En cilium hemos de añadir:

loadBalancer:
  serviceTopology: true

Revisar el tema de los "hints" que me ha dado tantos problemas

# Prerequisites

Error: failed to create fsnotify watcher: too many open files

sudo bash
echo "fs.inotify.max_user_watches=524288" | tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | tee -a /etc/sysctl.conf
sysctl -p

# Instalación

$ kind create cluster --name k8s-kind-oscar --config kind-cluster-config.yaml

$ helm upgrade --install cilium cilium/cilium -n kube-system -f values-cilium.yaml --version=1.19.3

$ k -n kube-system get pods -l app.kubernetes.io/part-of=cilium
NAME                              READY   STATUS    RESTARTS   AGE
cilium-5b4vc                      1/1     Running   0          2m9s
cilium-envoy-4fx4w                1/1     Running   0          2m9s
cilium-envoy-6wjjc                1/1     Running   0          2m9s
cilium-envoy-lr5n2                1/1     Running   0          2m9s
cilium-envoy-svhjh                1/1     Running   0          2m9s
cilium-envoy-tz2sr                1/1     Running   0          2m9s
cilium-j752d                      1/1     Running   0          2m9s
cilium-operator-8b589448d-drvm2   1/1     Running   0          2m9s
cilium-operator-8b589448d-wr4f6   1/1     Running   0          2m9s
cilium-v82lz                      1/1     Running   0          2m9s
cilium-w4zd4                      1/1     Running   0          2m9s
cilium-zv99d                      1/1     Running   0          2m9s

$ k get nodes -L topology.kubernetes.io/zone
NAME                           STATUS   ROLES           AGE     VERSION   ZONE
k8s-kind-oscar-control-plane   Ready    control-plane   3m8s    v1.35.1   
k8s-kind-oscar-worker          Ready    <none>          2m53s   v1.35.1   zone-a
k8s-kind-oscar-worker2         Ready    <none>          2m52s   v1.35.1   zone-a
k8s-kind-oscar-worker3         Ready    <none>          2m52s   v1.35.1   zone-b
k8s-kind-oscar-worker4         Ready    <none>          2m52s   v1.35.1   zone-b

# Testing

$ k apply -f 00-NS.yaml
$ k apply -f 05-Pod.yaml
$ k apply -f 10-Deployment.yaml
$ k apply -f 15-Service-Simple.yaml
$ k apply -f 16-Service-TrafficDistribution.yaml

$ k -n traffic-distribution get pods -L topology.kubernetes.io/zone
NAME                                   READY   STATUS    RESTARTS   AGE   ZONE
app-ilba-deployment-5ddfccd95d-559pb   1/1     Running   0          17s   zone-b
app-ilba-deployment-5ddfccd95d-bl6fs   1/1     Running   0          17s   zone-b
app-ilba-deployment-5ddfccd95d-dlrb6   1/1     Running   0          17s   zone-a
app-ilba-deployment-5ddfccd95d-mgfc2   1/1     Running   0          17s   zone-a
app-ilba-deployment-5ddfccd95d-n8n8n   1/1     Running   0          17s   zone-b
app-ilba-deployment-5ddfccd95d-phvhf   1/1     Running   0          17s   zone-a
app-ilba-deployment-5ddfccd95d-pnhh2   1/1     Running   0          17s   zone-b
app-ilba-deployment-5ddfccd95d-xb242   1/1     Running   0          17s   zone-a
client-zone-a                          1/1     Running   0          20s   zone-a
client-zone-b                          1/1     Running   0          20s   zone-b

$ k -n traffic-distribution get svc
NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
svc-simple                 ClusterIP   10.96.225.61   <none>        80/TCP    13m
svc-traffic-distribution   ClusterIP   10.96.185.63   <none>        80/TCP    3m20s


$ kubectl exec -n traffic-distribution client-zone-a -- sh -c '
for i in $(seq 1 10); do
  curl -s svc-simple
done' | grep Hostname


$ kubectl exec -n traffic-distribution client-zone-a -- sh -c '
for i in $(seq 1 10); do
  curl -s svc-traffic-distribution
done' | grep Hostname

Es importante revisar los:

$ k -n traffic-distribution get endpointslice

Nota por si queremos hacer un DaemonSet:
Para los DaemonSets, Kubernetes suele aplicar una lógica de "umbral". Si tienes pocos nodos por zona (en tu caso tienes 2 nodos en la zone-a y 2 en la zone-b), el controlador calcula que si un nodo falla, el tráfico de esa zona saturaría al único pod restante. Por seguridad, Kubernetes decide que es mejor repartir el tráfico entre todo el clúster (ignorar zonas) que arriesgarse a tirar el único pod sano de una zona.
