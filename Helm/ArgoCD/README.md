# Index:

* [Instalación de ArgoCD](#id10)
* [Instalación del binario de ArgoCD](#id20)
* [Creación token en GitLab](#id30)
* [Estructuca básica (create NS)](#id40)
* [Estructuca básica (ArgoCD)](#id50)

# Instalación de ArgoCD <div id='id10' />

Instalación de ArgoCD con Helm

```
root@k8s-test-cp:~# helm repo add argo https://argoproj.github.io/argo-helm
root@k8s-test-cp:~# helm repo update

root@k8s-test-cp:~# helm search repo argo-cd -l | head -n 5
NAME            CHART VERSION   APP VERSION     DESCRIPTION
argo/argo-cd    8.0.0           v3.0.0          A Helm chart for Argo CD, a declarative, GitOps...
argo/argo-cd    7.9.1           v2.14.11        A Helm chart for Argo CD, a declarative, GitOps...
argo/argo-cd    7.9.0           v2.14.11        A Helm chart for Argo CD, a declarative, GitOps...
argo/argo-cd    7.8.28          v2.14.11        A Helm chart for Argo CD, a declarative, GitOps...
```

```
$ cat >> values-argocd.yaml<< EOF
global:
  domain: argocd.ilba.cat
configs:  
  params:  
    server.insecure: true
server:
  ingress:
    enabled: true
    ingressClassName: "nginx"    
EOF
```

```
$ helm upgrade --install \
argocd argo/argo-cd \
--create-namespace \
--namespace argocd \
--version=7.9.1 \
-f values-argocd.yaml
```

Verificaciones:

```
root@k8s-test-cp:~# helm -n argocd ls
NAME    NAMESPACE       REVISION        UPDATED                                         STATUS          CHART           APP VERSION
argocd  argocd          1               2025-05-10 22:40:33.585081904 +0200 CEST        deployed        argo-cd-7.9.1   v2.14.11

root@k8s-test-cp:~# kubectl -n argocd get pods
NAME                                                READY   STATUS    RESTARTS   AGE
argocd-application-controller-0                     1/1     Running   0          86s
argocd-applicationset-controller-576d4f4789-hjbjf   1/1     Running   0          86s
argocd-dex-server-5969bdf86c-mtsww                  1/1     Running   0          86s
argocd-notifications-controller-57bd9c6665-wl59t    1/1     Running   0          86s
argocd-redis-67c8779476-hjrwh                       1/1     Running   0          86s
argocd-repo-server-75d87c494c-jxb9q                 1/1     Running   0          86s
argocd-server-7f6d88b9fd-22qsd                      1/1     Running   0          86s


root@k8s-test-cp:~# kubectl -n argocd get ingress
NAME                    CLASS   HOSTS             ADDRESS        PORTS   AGE
argocd-server-ingress   nginx   argocd.ilba.cat   172.26.0.101   80      18s
```

Verificación via web:

* Saber el password que nos ha puesto por defecto
```
root@k8s-test-cp:~# kubectl -n argocd \
get secret argocd-initial-admin-secret \
-o jsonpath="{.data.password}" | base64 -d; echo
```
* Verificación [via web](https://argocd.ilba.cat/)

# Instalación del binario de ArgoCD <div id='id20' />

Instalamos el binario de [ArgoCD](https://github.com/argoproj/argo-cd/tags)

```
root@k8s-test-cp:~# RELEASE_ARGOCD=`helm -n argocd ls | grep argocd | awk '{print $10}'`
root@k8s-test-cp:~# wget https://github.com/argoproj/argo-cd/releases/download/$RELEASE_ARGOCD/argocd-linux-amd64
root@k8s-test-cp:~# mv argocd-linux-amd64 /usr/local/bin/argocd
root@k8s-test-cp:~# chmod 755 /usr/local/bin/argocd
```

Verificamos el correcto funcionamiento:

```
root@k8s-test-cp:~# kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
26BvmBnaTa124Khw

root@k8s-test-cp:~# kubectl -n argocd get ingress
NAME            CLASS   HOSTS             ADDRESS        PORTS   AGE
argocd-server   nginx   argocd.ilba.cat   172.26.0.101   80      12h

root@k8s-test-cp:~# echo "172.26.0.101 argocd.ilba.cat" >> /etc/hosts

root@k8s-test-cp:~# argocd login --insecure --skip-test-tls --grpc-web --username admin --password 26BvmBnaTa124Khw argocd.ilba.cat
'admin:login' logged in successfully
Context 'argocd.ilba.cat' updated
```

# Creación token en GitLab <div id='id30' />

Creamos el token en GitLab, para ello nos hemos de desplazar al repositorio que vamos a usar en nuestro equipo de GitLab:
* Settings -> Repository -> Deploy tokens
* Campos a rellenar:
  * Name: gitlab-argocd-token
  * Scopes: read_repository

El token que nos da es el siguiente:

* Username: gitlab+deploy-token-1
* Token: gldt-35e8v2uj1cojhdLKQkLm

En el Gitlab, nos iremos a: "Code -> Repository", para saber la URL de repositorio: http://gitlab.ilba.cat/gitops/argocd.git

# Estructuca básica (create NS) <div id='id40' />

La estructura es la siguiente:

```
$ tree
.
├── README.md
└── bootstrap
    └── base
        ├── kustomization.yaml
        └── namespaces.yaml
```

```
$ cat bootstrap/base/namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: app-1

$ cat bootstrap/base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - namespaces.yaml
```

# Estructuca básica (ArgoCD) <div id='id50' />

```
root@k8s-test-cp:~# vim argocd.yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: argocd-private-repo
  namespace: argocd
  annotations:
    managed-by: argocd.argoproj.io
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: http://gitlab.ilba.cat/gitops/argocd.git
  username: gitlab+deploy-token-1
  password: gldt-35e8v2uj1cojhdLKQkLm
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: bootstrap
  namespace: argocd
spec:
  project: default
  source:
    repoURL: "http://gitlab.ilba.cat/gitops/argocd.git"
    path: "bootstrap/base"
    targetRevision: master
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
```

```
root@k8s-test-cp:~# kubectl apply -f argocd.yaml
```

```
root@k8s-test-cp:~# argocd repo list
TYPE  NAME  REPO                                      INSECURE  OCI    LFS    CREDS  STATUS      MESSAGE  PROJECT
git         http://gitlab.ilba.cat/gitops/argocd.git  false     false  false  true   Successful

root@k8s-test-cp:~# argocd app list
NAME              CLUSTER                         NAMESPACE  PROJECT  STATUS     HEALTH   SYNCPOLICY  CONDITIONS  REPO                                      PATH            TARGET
argocd/bootstrap  https://kubernetes.default.svc  argocd     default  OutOfSync  Healthy  Manual      <none>      http://gitlab.ilba.cat/gitops/argocd.git  bootstrap/base  master

root@k8s-test-cp:~# argocd app sync bootstrap

root@k8s-test-cp:~# kubectl get ns
NAME                    STATUS   AGE
app-1                   Active   18s
...                     ...      ...
```