# Index:

* [Gestión de IP Masquerading en Cilium con ipMasqAgent](#id10)
* [Validación con IP del Worker (Comportamiento por defecto)](#id20)
* [Configuración del IP Masquerading en Cilium](#id30)
* [Validación con IP real del Pod](#id40)

# Gestión de IP Masquerading en Cilium con ipMasqAgent <div id='id10' />

En este laboratorio veremos el funcionamiento del IP Masquerading nativo de Cilium.

Por defecto, el tráfico saliente del cluster hacia redes externas se enmascara con la IP del nodo worker. Configurando el ipMasqAgent de Cilium, conseguiremos que el tráfico mantenga la IP real del Pod al comunicarse con redes internas específicas de nuestra infraestructura.

# Validación con IP del Worker (Comportamiento por defecto)  <div id='id20' />

Por defecto, al realizar un telnet desde un Pod hacia un servidor externo (mldonkey), este registrará la IP física del nodo worker. Identificaremos la IP del worker (172.26.0.143):

```
root@k8s-cilium-01-cp:~# kubectl get nodes -o wide
NAME                 STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION        CONTAINER-RUNTIME
...
k8s-cilium-01-wk02   Ready    <none>          3d    v1.34.5   172.26.0.143   <none>        Debian GNU/Linux 13 (trixie)   6.12.86+deb13-amd64   containerd://2.2.3
...
```

Desplegamos un Pod de pruebas anclado en el worker (k8s-cilium-01-wk02):

```
root@k8s-cilium-01-cp:~# vim pod-worker2.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-worker02
  namespace: default
  labels:
    app: pod
spec:
  nodeName: k8s-cilium-01-wk02
  containers:
  - name: pod-worker02
    image: debian
    command: ["sleep", "infinity"]
  terminationGracePeriodSeconds: 0

root@k8s-cilium-01-cp:~# k apply -f pod-worker2.yaml
```

Instalamos telnet dentro del Pod y lanzamos una petición de prueba al servidor SMTP (mldonkey):

```
root@k8s-cilium-01-cp:~# k exec -it pod-worker02 -- bash
root@pod-worker02:/# apt update && apt install -y telnet
root@pod-worker02:/# telnet 172.26.0.68 25
```

Revisando los logs de Postfix en el servidor de destino, confirmamos que la conexión llega con la IP del worker (172.26.0.143):

```
root@mldonkey:~# tail -f /var/log/mail.log
May 17 06:36:02 mldonkey postfix/smtpd[1821]: connect from unknown[172.26.0.143]
May 17 06:36:04 mldonkey postfix/smtpd[1821]: disconnect from unknown[172.26.0.143] quit=1 commands=1
```

# Configuración del IP Masquerading en Cilium  <div id='id30' />

Para evitar el enmascaramiento hacia nuestras redes locales, habilitamos el agente de IP Masq en el [*values.yaml*](../ClusterMesh/cluster-apps/k8s-cilium-01/charts-values/values-cilium.yaml) de Cilium:

```
ipMasqAgent:
  enabled: true
bpf:
  masquerade: true
```

A continuación, creamos el ConfigMap ([*nonMasqueradeCIDRs.yaml*](../ClusterMesh/cluster-apps/k8s-cilium-01/configs/cilium/nonMasqueradeCIDRs.yaml)) donde definimos los rangos CIDR excluidos del NAT). Cualquier destino fuera de la lista (como Internet) se le segirá aplicando el masquerading.

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: ip-masq-agent
  namespace: kube-system
data:
  config: |
    nonMasqueradeCIDRs:
      - 10.1.0.0/16
      - 10.2.0.0/16
      - 172.26.0.0/24
    resyncInterval: 60s
```

# Validación con IP real del Pod  <div id='id40' />

Al desactivar el NAT para la red 172.26.0.0/24, el servidor de destino recibirá la IP del Pod (10.1.2.32). Para que la conexión TCP se complete con éxito, el servidor externo necesita conocer la ruta de retorno para responder al Pod:

```
[ Pod (10.1.2.32) ]  -------- (Ida) -------->  [ Servidor Mail (172.26.0.68) ]
                                                      |
[ Pod (10.1.2.32) ]  <-- (Vuelta: ¿Por dónde?) -------+
```

Añadimos la ruta estática en el servidor mldonkey apuntando al nodo que actúa como pasarela:

```
root@mldonkey:~# ip route add 10.1.0.0/16 via 172.26.0.143
```

Volvemos a probar la conectividad desde el Pod:

```
root@k8s-cilium-01-cp:~# k get pods -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP          NODE                 NOMINATED NODE   READINESS GATES
pod-worker02   1/1     Running   0          14m   10.1.2.32   k8s-cilium-01-wk02   <none>           <none>

root@k8s-cilium-01-cp:~# k exec -it pod-worker02 -- bash
root@pod-worker02:/# telnet 172.26.0.68 25
```

En los logs en mldonkey podremos ver la IP interna del Pod (10.1.2.32):

```
root@mldonkey:~# tail -f /var/log/mail.log
May 17 07:02:49 mldonkey postfix/smtpd[1981]: connect from unknown[10.1.2.32]
May 17 07:02:52 mldonkey postfix/smtpd[1981]: disconnect from unknown[10.1.2.32] quit=1 commands=1
```