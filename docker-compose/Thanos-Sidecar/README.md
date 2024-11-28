# Thanos

* [Getting Started](#id1)
* [Copiar configuraciones](#id10)
* [Proceso arrancado de contenedores + configs](#id20)

## Getting Started <div id='id1' />

Instalación base:

* docker-compose

Esquema:

```
                               +---+
                               |   |
                               |   |
                               |   |
                               +---+
                                
                          Name: prometheus-a
                           IP: 172.26.0.201


      +---+                                             +---+
      |   |                                             |   |
      |   |                                             |   |
      |   |                                             |   |
      +---+                                             +---+ 

Name: prometheus-b                                 Name: prometheus-c
 IP: 172.26.0.202                                   IP: 172.26.0.203
```

## Copiar configuraciones <div id='id10' />

```
$ scp files/docker-compose-prometheus-c.yaml 172.26.0.203:/etc/docker-compose/docker-compose.yaml
$ scp files/prometheus-prometheus-c.yml 172.26.0.203:/etc/docker-compose/prometheus.yml
$ scp files/bucket_config.yaml 172.26.0.203:/etc/docker-compose/bucket_config.yaml
```

```
$ scp files/docker-compose-prometheus-b.yaml 172.26.0.202:/etc/docker-compose/docker-compose.yaml
$ scp files/prometheus-prometheus-b.yml 172.26.0.202:/etc/docker-compose/prometheus.yml
$ scp files/bucket_config.yaml 172.26.0.202:/etc/docker-compose/bucket_config.yaml
```

```
$ scp files/docker-compose-prometheus-a.yaml 172.26.0.201:/etc/docker-compose/docker-compose.yaml
$ scp files/prometheus-prometheus-a.yml 172.26.0.201:/etc/docker-compose/prometheus.yml
$ scp files/bucket_config.yaml 172.26.0.201:/etc/docker-compose/bucket_config.yaml
```

## Proceso arrancado de contenedores + configs <div id='id20' />

### Arrancamos MinIO

```
root@prometheus-a:~# docker compose -f /etc/docker-compose/docker-compose.yaml up -d minio
```

Accederemos al MinIO y crearemos el bucket: **thanos**
* URL: http://172.26.0.201:9001/
* Username: admin
* Password: superpassword

![alt text](images/MinIO-create-bucket.png)

### Arrancamos promtheus-b + sidecar

```
root@prometheus-b:~# docker compose -f /etc/docker-compose/docker-compose.yaml up -d
```

```
root@prometheus-b:~# docker exec -it prometheus-b ash
/prometheus $ chmod 777 -R /prometheus
/prometheus $ exit
root@prometheus-b:~# docker restart prometheus-b thanos-sidecar
```

Verificaremos el correcto funcionamiento:
* URL: http://172.26.0.202:9090/targets?search=

![alt text](images/prometheus-b.png)

### Arrancamos promtheus-c + sidecar

```
root@prometheus-c:~# docker compose -f /etc/docker-compose/docker-compose.yaml up -d
```

```
root@prometheus-c:~# docker exec -it prometheus-c ash
/prometheus $ chmod 777 -R /prometheus
/prometheus $ exit
root@prometheus-c:~# docker restart prometheus-c thanos-sidecar
```

Verificaremos el correcto funcionamiento:
* URL: http://172.26.0.203:9090/targets?search=

![alt text](images/prometheus-c.png)

A partir de aquí (pasado un rato), podremos ver como se va llenando el bucket que hemos creado en el MinIO:

![alt text](images/MinIO-with-data.png)


### Arrancamos stack de Thanos

```
root@prometheus-a:~# docker compose -f /etc/docker-compose/docker-compose.yaml up -d
```

Podremos verificar el correcto funcionamiento:

![alt text](images/Thanos-targets.png)

![alt text](images/Thanos-query.png)