# Index:

* [Crear certificados](#id10)
* [Gestion de permisos](#id20)

# Crear certificados <div id='id10' />

Nota importante: cuando creamos el _csr_ con el OpenSSL, la "O=ilba", es el grupo que posteriormente se hace referencia en el _ClusterRoleBinding_ o en el _RoleBinding_

```
root@k8s-test-cp:~/rbac# openssl genrsa -out limit-user.key 4096
root@k8s-test-cp:~/rbac# openssl req -new -key limit-user.key -out limit-user.csr -subj "/CN=limit-user/O=ilba"
root@k8s-test-cp:~/rbac# openssl x509 -req -in limit-user.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out limit-user.crt -days 1
```

```
root@k8s-test-cp:~/rbac# ls -la
total 20
drwxr-xr-x  2 root root 4096 Jun 29 10:28 .
drwx------ 12 root root 4096 Jun 29 10:25 ..
-rw-r--r--  1 root root 1363 Jun 29 10:28 limit-user.crt
-rw-r--r--  1 root root 1606 Jun 29 10:28 limit-user.csr
-rw-------  1 root root 3272 Jun 29 10:28 limit-user.key

root@k8s-test-cp:~/rbac# openssl x509 -in limit-user.crt -text | grep Validity -A2
        Validity
            Not Before: Jun 29 08:28:32 2025 GMT
            Not After : Jun 30 08:28:32 2025 GMT
```

Para realizar la gestión de los contextos, hemos de instalar [Krew](https://krew.sigs.k8s.io/docs/user-guide/setup/install/)


```
root@k8s-test-cp:~/rbac# kubectl config set-credentials limit-user --client-certificate=limit-user.crt --client-key=limit-user.key
root@k8s-test-cp:~/rbac# kubectl config set-context limit-user-context --cluster=cluster.local --namespace=default --user=limit-user

root@k8s-test-cp:~/rbac# vim ../.bashrc
  export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

root@k8s-test-cp:~/rbac# . ../.bashrc
root@k8s-test-cp:~/rbac# k krew install ctx

root@k8s-test-cp:~/rbac# k ctx
kubernetes-admin@cluster.local
limit-user-context
```

# Gestion de permisos <div id='id20' />

Ejemplo de permisos:

```
root@k8s-test-cp:~/rbac# vim limit-user.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cr-readonly
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crb-group-ilba-readonly
subjects:
- kind: Group
  name: ilba
roleRef:
  kind: ClusterRole
  name: cr-readonly
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: r-allow-all
  namespace: ca-test-01
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rb-group-ilba-allow-all
  namespace: ca-test-01
subjects:
- kind: Group
  name: ilba
roleRef:
  kind: Role
  name: r-allow-all
```

```
root@k8s-test-cp:~/rbac# k apply -f limit-user.yaml
root@k8s-test-cp:~/rbac# k ctx limit-user-context
```

Verificaciones:

* :heavy_check_mark: root@k8s-test-cp:~/rbac# k get ns
* :heavy_check_mark: root@k8s-test-cp:~/rbac# k -n argocd get pods
* :x: root@k8s-test-cp:~/rbac# k -n argocd delete pod argocd-application-controller-0
* :x: root@k8s-test-cp:~/rbac# kubectl -n cx-test-01 run debug -it --image=debian
* :x: root@k8s-test-cp:~/rbac# kubectl -n cb-test-01 run debug -it --image=debian
* :heavy_check_mark: root@k8s-test-cp:~/rbac# kubectl -n ca-test-01 run debug -it --image=debian
* :heavy_check_mark: root@k8s-test-cp:~/rbac# kubectl -n ca-test-01 get pods
* :heavy_check_mark: root@k8s-test-cp:~/rbac# kubectl -n ca-test-01 delete pod debug
* :x: root@k8s-test-cp:~/rbac# k delete ns loki