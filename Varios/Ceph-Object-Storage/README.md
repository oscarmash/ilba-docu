# Index:

* [Esquema](#id10)
* [Configuración](#id20)

# Esquema <div id='id10' />

En Ceph se llama: Ceph Object Gateway o RADOS Gateway (RGW), pero realmente es el sistema de [Object Storage](https://en.wikipedia.org/wiki/Object_storage)

xxxxx

# Configuración <div id='id10' />


```
root@ceph-aio:~# ceph -s
  cluster:
    id:     7d2b3cca-f1eb-11ee-a886-593bc87d3824
    health: HEALTH_OK
            (muted: POOL_NO_REDUNDANCY)

  services:
    mon: 1 daemons, quorum ceph-aio (age 75s)
    mgr: ceph-aio.iaeehz(active, since 17s)
    osd: 3 osds: 3 up (since 27s), 3 in (since 5M)

  data:
    pools:   1 pools, 1 pgs
    objects: 2 objects, 449 KiB
    usage:   891 MiB used, 89 GiB / 90 GiB avail
    pgs:     1 active+clean

  io:
    client:   1.7 KiB/s rd, 22 KiB/s wr, 1 op/s rd, 1 op/s wr
```

```
root@ceph-aio:~# ceph orch apply rgw rgw_ilba
Scheduled rgw.rgw_ilba update...

root@ceph-aio:~# ceph orch host label add ceph-aio rgw
Added label rgw to host ceph-aio

root@ceph-aio:~# ceph orch apply rgw rgw_ilba
Scheduled rgw.rgw_ilba update...


```

https://docs.ceph.com/en/latest/cephadm/services/rgw/


https://docs.redhat.com/en/documentation/red_hat_ceph_storage/5/html/object_gateway_guide/deployment#deploying-the-ceph-object-gateway-using-the-command-line-interface_rgw