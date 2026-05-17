# Index

* [Prerrequisitos del entorno](#id10)
* [Habilitar el flag de BandwidthManager](#id20)
* [Despliegue del escenario de pruebas](#id30)
* [Verificación del ancho de banda (sin restricciones)](#id40)
* [Aplicación y validación de límites de ancho de banda](#id50)
* [Limpieza y restauración al estado inicial](#id60)

# Prerequisitos <div id='id10' />

No es posible utilizar este sistema en entornos locales basados en Kind. BandwidthManager requiere acceso directo a ciertos parámetros de *sysctl* del equipo. Como por ejemplo: */proc/sys/net/core*.

Para realizar esta prueba, es imprescindible contar con un entorno Bare Metal o basado en Máquinas Virtuales (VM), ya que se necesita acceso completo al kernel del sistema operativo subyacente.

# Habilitar el flag de BandwidthManager <div id='id20' />

Para que funcione el sistema de BandwidthManager, hemos de habilitar el flag en el *values.yaml*:

Para que funcione el sistema de BandwidthManager, debemos asegurarnos de habilitar el flag correspondiente en el archivo *values.yaml* de Cilium:

```
bandwidthManager:
  enabled: true
```

Antes de aplicar el flag, verificaremos que BandwidthManager se encuentra deshabilitado. Una vez habilitado, validaremos que se haya activado correctamente:

```
root@k8s-cilium-01-cp:~# kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep BandwidthManager
BandwidthManager:        Disabled

$ cd $HOME/ilba/ilba-docu/Varios-k8s/Cilium/ClusterMesh/
$ make install_applications_tag ENV=k8s-cilium-01 TAG=cilium_installation

root@k8s-cilium-01-cp:~# kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep BandwidthManager
BandwidthManager:    EDT with BPF [CUBIC] [ens18]
```

# Despliegue del escenario de pruebas <div id='id30' />

Para comprobar el correcto funcionamiento del limitador, utilizaremos dos Pods basados en la imagen *cilium/netperf* (un cliente y un servidor). Usaremos reglas de anti-afinidad para asegurar que los pods estén en distintos nodos.

```
root@k8s-cilium-01-cp:~# cat bandwidth-manager-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    app.kubernetes.io/name: netperf-server
  name: netperf-server
  namespace: default
spec:
  containers:
  - name: netperf
    image: cilium/netperf
    ports:
    - containerPort: 12865
---
apiVersion: v1
kind: Pod
metadata:
  name: netperf-client
  namespace: default
spec:
  affinity:
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app.kubernetes.io/name
            operator: In
            values:
            - netperf-server
        topologyKey: kubernetes.io/hostname
  containers:
  - name: netperf
    args:
    - sleep
    - infinity
    image: cilium/netperf
```

```
root@k8s-cilium-01-cp:~# k apply -f bandwidth-manager-pods.yaml
```

Obtenemos la IP asignada al Pod servidor (netperf-server) y la guardamos en una variable de entorno para facilitar los comandos posteriores:

```
root@k8s-cilium-01-cp:~# kubectl get pods -o wide
NAME             READY   STATUS    RESTARTS   AGE   IP           NODE                 NOMINATED NODE   READINESS GATES
netperf-client   1/1     Running   0          39s   10.1.3.222   k8s-cilium-01-wk03   <none>           <none>
netperf-server   1/1     Running   0          39s   10.1.1.140   k8s-cilium-01-wk01   <none>           <none>

root@k8s-cilium-01-cp:~# NETPERF_SERVER_IP=10.1.1.140
```

# Verificación del ancho de banda (sin restricciones) <div id='id40' />

Primero, lanzamos un test de rendimiento desde el cliente sin aplicar ningún tipo de limitación. Esto nos servirá como línea base para comparar (en este caso, obtenemos **879.89 Mbps**):

```
root@k8s-cilium-01-cp:~# k exec netperf-client -- netperf -t TCP_MAERTS -H "${NETPERF_SERVER_IP}"
Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    10.00     879.89
```

# Aplicación y validación de límites de ancho de banda <div id='id50' />


Añadimos la anotación nativa de Kubernetes al Pod para limitar el ancho de banda de salida (egress) a 5 Megabits:

```
root@k8s-cilium-01-cp:~# k annotate pod/netperf-server kubernetes.io/egress-bandwidth="5M"
```

Volvemos a ejecutar la prueba de rendimiento. Veremos que el tráfico se capa de forma efectiva y no supera el umbral establecido (se estabiliza en **4.76 Mbps**):

```
root@k8s-cilium-01-cp:~# k exec netperf-client -- netperf -t TCP_MAERTS -H "${NETPERF_SERVER_IP}"
Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    10.01       4.76
```

# Limpieza y restauración al estado inicial <div id='id60' />

Por último, removemos la anotación del Pod (añadiendo un guion - al final) para comprobar que el tráfico recupera su velocidad original (alcanzando de nuevo los **1030.11 Mbps**):

```
root@k8s-cilium-01-cp:~# k annotate pod/netperf-server kubernetes.io/egress-bandwidth-

root@k8s-cilium-01-cp:~# k exec netperf-client -- netperf -t TCP_MAERTS -H "${NETPERF_SERVER_IP}"
Recv   Send    Send
Socket Socket  Message  Elapsed
Size   Size    Size     Time     Throughput
bytes  bytes   bytes    secs.    10^6bits/sec

131072  16384  16384    10.00    1030.11
```