# Index:

* [Eliminar una política](#id10)

# Eliminar una política <div id='id10' />


```
root@ilimit-paas-k8s-pre-cp01:~# calicoctl get NetworkPolicy -A
NAMESPACE              NAME
...
cb-mercadona-website   cb-mercadona-website-basic-stack-netpolicy-allow
...
```

```
root@ilimit-paas-k8s-pre-cp01:~# calicoctl delete policy cb-mercadona-website-basic-stack-netpolicy-allow --namespace=cb-mercadona-website
Successfully deleted 1 'NetworkPolicy' resource(s)
```
