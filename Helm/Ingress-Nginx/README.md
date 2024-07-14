# Index:

* [Instalación de Ingress](#id10)
* [Custom del ingress](#id20)
  * [Default backend](#id30) FALLA


# Instalación de Ingress <div id='id10' />

Antes de desplegar el Ingress-Nginx, necesitamos haber desplegado previamente el MetalLB.

```
root@kubespray-aio:~# vim values-nginx.yaml
controller:
  service:
    type: LoadBalancer
    externalTrafficPolicy: "Local"
  publishService:
    enabled: true
  kind: DaemonSet
```

```
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace ingress-nginx \
--version=4.9.0 \
-f values-nginx.yaml
```

```
root@kubespray-aio:~# helm -n ingress-nginx ls
NAME            NAMESPACE       REVISION        UPDATED                                         STATUS          CHART                   APP VERSION
ingress-nginx   ingress-nginx   2               2024-07-06 13:55:52.060244198 +0200 CEST        deployed        ingress-nginx-4.9.0     1.9.5

root@kubespray-aio:~# kubectl -n ingress-nginx get pods
NAME                             READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-hdnxm   1/1     Running   0          28m
ingress-nginx-controller-k6dhj   1/1     Running   0          28m
ingress-nginx-controller-nsv89   1/1     Running   0          28m
```

:memo: Faltaría, verificar desplegando algo que accediera por ingress.......

# Custom del ingress <div id='id20' />

## Default backend <div id='id30' />


```
root@kubespray-aio:~# vim custom-default-backend-error-pages.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-error-pages
  namespace: ingress-nginx
data:
  error: |
    <!DOCTYPE html>
    <html>
      <head><title>DOMINI NO CONFIGURAT</title></head>
    </html>

root@kubespray-aio:~# kubectl apply -f custom-default-backend-error-pages.yaml
```

Podemos encontrar las versiones de los contenedores aquí: https://github.com/kubernetes/k8s.io/blob/main/k8s.gcr.io/images/k8s-staging-ingress-nginx/images.yaml#L221

```
root@kubespray-aio:~# vim values-nginx.yaml
controller:
  service:
    type: LoadBalancer
    externalTrafficPolicy: "Local"
  publishService:
    enabled: true
  kind: DaemonSet
  custom-http-errors: "404,500,503"
defaultBackend:
  enabled: true
  image:
    registry: k8s.gcr.io
    image: ingress-nginx/nginx-errors
    tag: "v20230312-helm-chart-4.5.2-28-g66a760794"
  extraVolumes:
  - name: error-page
    configMap:
      name: custom-error-pages
      items:
      - key: "error"
        path: "404.html"
      - key: "error"
        path: "500.html"
      - key: "error"
        path: "503.html"
  extraVolumeMounts:
  - name: error-page
    mountPath: /www
```

```
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace ingress-nginx \
--version=4.9.0 \
-f values-nginx.yaml
```

```
root@kubespray-aio:~# kubectl -n ingress-nginx get pods
NAME                                            READY   STATUS    RESTARTS   AGE
ingress-nginx-controller-t9vwb                  1/1     Running   0          56s
ingress-nginx-controller-wd7zv                  1/1     Running   0          23s
ingress-nginx-controller-znb7g                  1/1     Running   0          88s
ingress-nginx-defaultbackend-77c9b4fc47-dgt8z   1/1     Running   0          13s
```

```
root@kubespray-aio:~# curl -sI -o /dev/null -w "%{http_code}\n" -H "Host: www.dominio.inventado.cat" "http://172.26.0.101/"
404

root@kubespray-aio:~# curl -H "Host: www.dominio.inventado.cat" "http://172.26.0.101/"
<!DOCTYPE html>
<html>
  <head><title>DOMINI NO CONFIGURAT</title></head>
</html>
```

Verificaremos que no salgan errores del siguiente tipo:

```
2024/07/06 12:33:56 format not specified. Using text/html
2024/07/06 12:33:56 unexpected error reading return code: strconv.Atoi: parsing "": invalid syntax. Using 404
2024/07/06 12:33:56 serving custom error response for code 404 and format text/html from file /www/404.html
```
```
root@kubespray-aio:~# POD=`kubectl -n ingress-nginx get pods | grep defaultbackend | awk '{print $1}' | tail -1`
root@kubespray-aio:~# kubectl -n ingress-nginx logs -f $POD
```
