# Index Ceph - Baja de Ceph RBD + CephFS:

* [Listado a dar de baja](#id10)
  * [Baja CephRBD](#id20)
  * [Baja CephFS](#id20)
  * [Baja Usuarios](#id20)

# Listado a dar de baja <div id='id10' />

Cosas que se han de dar de baja:

* Baja CephRBD
* Baja CephFS
* Baja Usuarios

```
root@vrt-hv01:~# ceph osd lspools
20 ilimit-paas-k8s
23 cephfs.ilimit-paas-k8s-cephfs.meta
24 cephfs.ilimit-paas-k8s-cephfs.data
```

# Baja CephRBD <div id='id20' />

```
root@vrt-hv01:~# pveceph pool destroy ilimit-paas-k8s --force
```

# Baja CephFS <div id='id30' />

```
root@vrt-hv01:~# ceph fs ls
name: iso, metadata pool: iso_metadata, data pools: [iso_data ]
name: ilimit-paas-k8s-cephfs, metadata pool: cephfs.ilimit-paas-k8s-cephfs.meta, data pools: [cephfs.ilimit-paas-k8s-cephfs.data ]
name: ilimit-paas-k8s-provi-cephfs, metadata pool: cephfs.ilimit-paas-k8s-provi-cephfs.meta, data pools: [cephfs.ilimit-paas-k8s-provi-cephfs.data ]
name: ilimit-paas-k8s-pre-cephfs, metadata pool: cephfs.ilimit-paas-k8s-pre-cephfs.meta, data pools: [cephfs.ilimit-paas-k8s-pre-cephfs.data ]

root@vrt-hv01:~# ceph fs status ilimit-paas-k8s-cephfs
ilimit-paas-k8s-cephfs - 0 clients
======================
RANK  STATE     MDS        ACTIVITY     DNS    INOS   DIRS   CAPS
 0    active  vrt-hv06  Reqs:    0 /s  41.8k  35.9k  3363      0
               POOL                   TYPE     USED  AVAIL
cephfs.ilimit-paas-k8s-cephfs.meta  metadata   751M  22.0T
cephfs.ilimit-paas-k8s-cephfs.data    data    17.5G  22.0T
STANDBY MDS
  vrt-xxx
MDS version: ceph version 18.2.2 (e9fe820e7fffd1b7cde143a9f77653b73fcec748) reef (stable)

root@vrt-hv01:~# ceph fs set ilimit-paas-k8s-cephfs down true
ilimit-paas-k8s-cephfs marked down.


root@vrt-hv01:~# ceph fs status ilimit-paas-k8s-cephfs
ilimit-paas-k8s-cephfs - 0 clients
======================
               POOL                   TYPE     USED  AVAIL
cephfs.ilimit-paas-k8s-cephfs.meta  metadata  19.9M  22.0T
cephfs.ilimit-paas-k8s-cephfs.data    data    17.5G  22.0T
STANDBY MDS
  vrt-xxx
MDS version: ceph version 18.2.2 (e9fe820e7fffd1b7cde143a9f77653b73fcec748) reef (stable)

root@vrt-hv01:~# ceph fs rm ilimit-paas-k8s-cephfs --yes-i-really-mean-it

root@vrt-hv01:~# ceph fs ls
name: iso, metadata pool: iso_metadata, data pools: [iso_data ]
name: ilimit-paas-k8s-provi-cephfs, metadata pool: cephfs.ilimit-paas-k8s-provi-cephfs.meta, data pools: [cephfs.ilimit-paas-k8s-provi-cephfs.data ]
name: ilimit-paas-k8s-pre-cephfs, metadata pool: cephfs.ilimit-paas-k8s-pre-cephfs.meta, data pools: [cephfs.ilimit-paas-k8s-pre-cephfs.data ]


root@vrt-hv01:~# ceph osd lspools
23 cephfs.ilimit-paas-k8s-cephfs.meta
24 cephfs.ilimit-paas-k8s-cephfs.data

root@vrt-hv01:~# pveceph pool destroy cephfs.ilimit-paas-k8s-cephfs.meta --force
root@vrt-hv01:~# pveceph pool destroy cephfs.ilimit-paas-k8s-cephfs.data --force
```

# Baja Usuarios <div id='id40' />

```
root@vrt-hv01:~# ceph auth list | grep ilimit-paas-k8s
client.ilimit-paas-k8s
        caps: [osd] allow rwx pool=ilimit-paas-k8s
client.ilimit-paas-k8s-cephfs
client.ilimit-paas-k8s-pre
        caps: [osd] allow rwx pool=ilimit-paas-k8s-pre
client.ilimit-paas-k8s-pre-cephfs
        caps: [mds] allow rw, allow rw path=/, allow rw fsname=ilimit-paas-k8s-pre-cephfs
client.ilimit-paas-k8s-provi
        caps: [osd] allow rwx pool=ilimit-paas-k8s-provi
client.ilimit-paas-k8s-provi-cephfs
        caps: [mds] allow rw fsname=ilimit-paas-k8s-provi-cephfs
        caps: [mon] allow r fsname=ilimit-paas-k8s-provi-cephfs
        caps: [osd] allow rw tag cephfs data=ilimit-paas-k8s-provi-cephfs
```

```
root@vrt-hv01:~# ceph auth get client.ilimit-paas-k8s
root@vrt-hv01:~# ceph auth get client.ilimit-paas-k8s-cephfs

root@vrt-hv01:~# ceph auth del client.ilimit-paas-k8s
root@vrt-hv01:~# ceph auth del client.ilimit-paas-k8s-cephfs
```

```
root@vrt-hv01:~# ceph auth list | grep ilimit-paas-k8s
client.ilimit-paas-k8s-pre
        caps: [osd] allow rwx pool=ilimit-paas-k8s-pre
client.ilimit-paas-k8s-pre-cephfs
        caps: [mds] allow rw, allow rw path=/, allow rw fsname=ilimit-paas-k8s-pre-cephfs
client.ilimit-paas-k8s-provi
        caps: [osd] allow rwx pool=ilimit-paas-k8s-provi
client.ilimit-paas-k8s-provi-cephfs
        caps: [mds] allow rw fsname=ilimit-paas-k8s-provi-cephfs
        caps: [mon] allow r fsname=ilimit-paas-k8s-provi-cephfs
        caps: [osd] allow rw tag cephfs data=ilimit-paas-k8s-provi-cephfs
```

