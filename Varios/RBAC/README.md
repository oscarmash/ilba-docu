# Index:

* [Crear certificados](#id10)
* [Gestion de permisos](#id20)
* [Ejemplo Ilimit](#id30)
  * [Autenticación](#id31)
  * [Autorización](#id32)

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

# Ejemplo Ilimit <div id='id30' />

## Autenticación <div id='id31' />

Todo este proceso, se lanza desde el CP

```
$ user='user-second-client'
$ group='group-second-client'
$ namespace='cd-second-client'

$ k8s_certificate_authority_data='LS0tLS1CRUdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxFLS0tLS0K'
$ k8s_server='https://80.94.7.16:6443'
$ k8s_cluster_name='ilimit-paas-k8s-pre'

$ openssl genrsa -out $user.key 4096
$ openssl req -new -key $user.key -out $user.csr -subj "/CN=$user/O=$group"
$ openssl x509 -req -in $user.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out $user.crt -days 365
```

Esto para hacer el fichero _.kube/config_ que le daremos al client:

```
$ cert=`cat $user.crt | base64 -w 0`
$ key=`cat $user.key | base64 -w 0`

echo "
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: $k8s_certificate_authority_data
    server: $k8s_server
  name: $k8s_cluster_name
contexts:
- context:
    cluster: $k8s_cluster_name
    user: $user@$k8s_cluster_name
    namespace: $namespace
  name: $user@$k8s_cluster_name
current-context: $user@$k8s_cluster_name
kind: Config
preferences: {}
users:
- name: $user@$k8s_cluster_name
  user:
    client-certificate-data: $cert
    client-key-data: $key" > $user-$k8s_cluster_name.kube.config
```

## Autorización <div id='id32' />

```
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: role-allow-custom
  namespace: cd-second-client
rules:
- apiGroups: ["*"]
  # kubectl api-resources -o wide
  resources:
    # CRD de Kubernetes
    - pods
    - pods/log
    - pods/exec
    - deployments
    - replicasets
    - statefulsets
    - services
    - configmaps
    - secrets
    - persistentvolumeclaims
    - horizontalpodautoscalers
    - cronjobs
    - jobs
    #- certificates
    #- certificaterequests
    - events
    - ingresses
    # CRD de Velero
    #- backups.velero
    # CRD de Operators
    #- xxxx
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rolebinding-allow-custom
  namespace: cd-second-client
subjects:
- kind: Group
  name: group-second-client # = $group de la autenticación
roleRef:
  kind: Role
  name: role-allow-custom
```  