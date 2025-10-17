* [Aplicaciones](#id1)
  * [App de test](#id10) (nginx)


# Aplicaciones <div id='id1' />

## App de test (nginx) <div id='id10' />


```
$ cd $HOME/ilba/ilba-docu/raspberry-pi/apps/files
$ scp test-app-hello-kubernetes.yaml oscar.mas@172.26.0.111:
```

```
oscar.mas@2025-05:~ $ kcaf test-app-hello-kubernetes.yaml
```

```
oscar.mas@2025-05:~ $ k -n test-ingress get ingress
NAME               CLASS    HOSTS                      ADDRESS        PORTS   AGE
app-ilba-ingress   cilium   test-ingress.pi.ilba.cat   172.26.0.110   80      60s

oscar.mas@2025-05:~ $ curl -s -H "Host: test-ingress.pi.ilba.cat" 172.26.0.110
<html>
<h1>Hello Kubernetes</h1>
<body>
This is Nginx Server
</body>
</html>
```
