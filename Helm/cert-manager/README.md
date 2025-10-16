# Index:

* [Checking básico](#id10)
* [Solicitar un certificado de prueba](#id11)

# Checking básico <div id='id10' />

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

# Solicitar un certificado de prueba <div id='id11' />

Creación de un certificado de pruebas

```
$ k create ns test-cert-manager
```
```
$ vim test-cert-manager.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: clusterissuer-test
spec:
  acme:
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    email: oscar.mas@ilimit.net
    privateKeySecretRef:
      name: letsencrypt-key
    solvers:
    - http01:
        ingress:
          class: nginx
---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: certificate-test
  namespace: test-cert-manager
spec:
  dnsNames:
  - test-cert-manager.ops.paas.ilimit.com
  issuerRef:
    group: cert-manager.io
    kind: ClusterIssuer
    name: clusterissuer-test
  secretName: test-cert-manager-secret
```

```
$ k apply -f test-cert-manager.yaml

$ kubectl -n test-cert-manager get certificates
NAME               READY   SECRET                     AGE
certificate-test   True    test-cert-manager-secret   2m52s

$  kubectl -n test-cert-manager get certificaterequests
NAME                 APPROVED   DENIED   READY   ISSUER               REQUESTER                                         AGE
certificate-test-1   True                True    clusterissuer-test   system:serviceaccount:cert-manager:cert-manager   3m27s

$ kubectl -n test-cert-manager get orders
NAME                            STATE   AGE
certificate-test-1-3931678042   valid   3m51s

$ kubectl get ClusterIssuer clusterissuer-test
NAME                 READY   AGE
clusterissuer-test   True    4m45s

$ k delete -f test-cert-manager.yaml
$ k delete ns test-cert-manager
```