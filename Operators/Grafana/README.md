# Operator de Grafana

* [CRD's](#id10)

## CRD's <div id='id0' />

```
$ k get grafana.grafana
NAME                       VERSION   STAGE      STAGE STATUS   AGE
cd-ilba-web-grafana        11.3.0    complete   success        2d11h
```

```
$ k get grafanadatasource
NAME                                             NO MATCHING INSTANCES   LAST RESYNC   AGE
cd-ilba-web-grafana-datasource-loki                                      2m2s          2d11h
cd-ilba-web-grafana-datasource-prometheus                                119s          2d11h
```

```
$ k get grafanadashboards
NAME                                                      NO MATCHING INSTANCES   LAST RESYNC   AGE
cd-ilba-web-grafana-dashboard-compute-resources                                   2m29s         2d11h
cd-ilba-web-grafana-dashboard-logs                                                2m35s         2d11h
cd-ilba-web-grafana-dashboard-networking-resources                                2m33s         2d11h
```