# Index:

* [Checking](#id10)

# Checking <div id='id10' />

Procedimiento de verificación ante un posible error:

```
$ kubectl -n cert-manager get pods
NAME                                      READY   STATUS    RESTARTS   AGE
cert-manager-5c86944dc6-gpgwr             1/1     Running   0          24m
cert-manager-cainjector-bc8dbfcdd-27mqd   1/1     Running   0          24m
cert-manager-webhook-5f65ff988f-9bsdd     1/1     Running   0          24m
```

El orden de debug es:
1. Certificates
2. Certificate Requests
3. Orders
4. Challenges
5. Cluster Issuer

```
$ kubectl -n argocd get certificates -o wide
$ kubectl -n argocd get certificaterequests -o wide
$ kubectl -n argocd get orders -o wide
$ kubectl -n argocd get challenges
$ kubectl get ClusterIssuer
```
