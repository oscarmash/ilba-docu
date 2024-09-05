# Index:

* [Instalación de Zabbix](#id10)
* [Configuración en servidor de Zabbix](#id20)

# Instalación de Zabbix <div id='id10' />


```
$ cat values.yaml
zabbixAgent:
  enabled: true
zabbixProxy:
  nodeSelector:
    workload: lan
  env:
    - name: ZBX_HOSTNAME
      value: ajt-terrassa-prefiware     # Nombre del proxy que pondremos en Zabbix Server
    - name: ZBX_SERVER_HOST
      value: "10.1.0.52"                # IP del Zabbix Server
    - name: ZBX_CACHESIZE
      value: 256M
```

```
$ helm search repo zabbix -l | head -n 2
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
zabbix-chart-6.0/zabbix-helm-chrt       1.3.5           6.0.28          A Helm chart for deploying Zabbix agent and proxy

$ helm upgrade --install \
zabbix zabbix-chart-6.0/zabbix-helm-chrt \
--create-namespace \
--namespace zabbix-proxy \
--version=1.3.5 \
-f .yaml
```

# Configuración en servidor de Zabbix <div id='id20' />

Creamos el proxy en el servidor de Zabbix:

![alt text](images/proxy.png)

Sólo hay que crear dos "equipos" con las templates indicadas:
* Kubernetes_nodes_by_HTTP
* Kubernetes_cluster_state_by_HTTP


Necesitaremos los siguientes datos:

* Token:
```
$ kubectl get secret zabbix-service-account -n zabbix-proxy -o jsonpath={.data.token} | base64 -d
```
* URL de la API:
```
$ kubectl cluster-info
```

A partir de aquí realizaremos la configuración:

![alt text](images/template-1-1.png)

![alt text](images/template-1-2.png)

![alt text](images/template-2-1.png)

![alt text](images/template-2-2.png)

Ha de quedar así:

![alt text](images/end.png)