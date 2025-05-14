# Index:

* [Prerrequisitos](#id00)
* [Instalación de ArgoCD](#id10)
* [Instalación del binario de ArgoCD](#id20)
* [Creación token en GitLab](#id30)
* [Estructuca básica (create NS)](#id40)
* [Estructuca básica (ArgoCD)](#id50)
* [Working daily](#id900)
  * [LAST SYNC se queda SYNC](#id901)
  * [SYNC STATUS vs LAST SYNC](#id902)
  * [Delete resources from ArgoCD](#id903)
  * [Synchronize options from ArgoCD](#id904)

# Prerrequisitos <div id='id00' />

Antes de desplegar nada, hemos de cumplir los siguientes prerrequisitos:

* Tener un cluster desplegado:

```
root@k8s-test-cp:~# kubectl get nodes
NAME            STATUS   ROLES           AGE   VERSION
k8s-test-cp     Ready    control-plane   64d   v1.30.4
k8s-test-wk01   Ready    <none>          64d   v1.30.4
k8s-test-wk02   Ready    <none>          64d   v1.30.4
k8s-test-wk03   Ready    <none>          64d   v1.30.4
```

* Tener un storage:

```
root@k8s-test-cp:~# kubectl get sc
NAME                   PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc (default)   rbd.csi.ceph.com   Delete          Immediate           true                   44h
```

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

# Working daily <div id='id900' />

## LAST SYNC se queda SYNC <div id='id901' />

```
$ argocd --grpc-web --insecure --username admin login gitops.pre.paas.ilimit.com
$ argocd app terminate-op helm-picto-advanced-stack
```

## SYNC STATUS vs LAST SYNC <div id='id902' />

![alt text](images/sync_status.png)

```
Repo <- SYNC STATUS <- ArgoCD -> LAST SYNC -> Cluster
```

## Delete resources from ArgoCD <div id='id903' />

Cuando borramos resources con ArgoCD, podemos ver las siguientes opciones:

![alt text](images/delete_resources.png)

```
Deployment (Parent)
  |
  |-- ReplicaSet (Child)
       |
       |-- Pods (Child) 
```

* Foreground: 
   * Waits for all child resources to be deleted before deleting the parent resource.
   * Use when you have complex applications with dependencies, and you want to ensure a clean and orderly deletion process.
   * Pods are deleted first, then the ReplicaSet, and finally the Deployment.
*  Background
   * Deletes the parent resource immediately, and the garbage collector then deletes the child resources.
   *  Use when you need to delete parent resources quickly and can tolerate asynchronous cleanup of child resources
   * Deployment is deleted immediately, and the garbage collector takes care of deleting the ReplicaSet and Pods in the background.
* Orphan
   * Deletes the parent resource but leaves the child resources untouched.
   *  Use when you want to retain child resources even after the parent resource is deleted, for example, to analyze their state or repurpose them.
   * Deployment is deleted, but the ReplicaSet and Pods remain in the cluster.

## Synchronize options from ArgoCD <div id='id904' />

![alt text](images/synchronize_options.png)

Sync Options:

* PRUNE
  * Enables automatic deletion of resources that are no longer defined in Git
  * Common use cases:
    * Cleaning up deprecated resources
    * Maintaining environment consistency
* DRY RUN
  * In some cases the CRD is not part of the sync, but it could be created in another way, e.g. by a controller in the cluster. An example is gatekeeper (Policy Controller for Kubernetes), which creates CRDs in response to user defined ConstraintTemplates. ArgoCD cannot find the CRD in the sync and will fail with the error: *the server could not find the requested resource*
* APPLY ONLY
  * Argo CD is going to skip pre/post sync hooks and just run kubectl apply for application resources.
* FORCE
  * For certain resources you might want to delete and recreate. e.g. job resources that should run every time when syncing.
  * **Warning:** This sync option has a destructive action, which could cause an outage for your application

Sync Options:

* SKIP SCHEMA VALIDATION
  * Bypasses Kubernetes schema validation
  * **Warning:** Can lead to invalid resource states
* PRUNE LAST
  * Deletes resources only after all other sync operations complete
  * Crucial for:
    * Database migrations
    * Stateful application updates
* RESPECT IGNORE DIFFERENCES
  * Honors the ignoreDifferences configuration
  * Useful for:
    * Fields managed by controllers
    * Dynamic or auto-generated values
* AUTO-CREATE NAMESPACE
  * Automatically creates target namespace if it doesn't exist
* APPLY OUT OF SYNC ONLY
  * Only syncs resources that differ from desired state
  * Advantages:
    * Reduced API server load
    * Faster sync operations
    * Minimized disruption
* SERVER-SIDE APPLY
  * No la entiendo: https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/#server-side-apply

Sync Options:

* REPLACE
  * Forces complete resource replacement instead of patching
  * Important for:
    * Breaking out of invalid states
    * Complete resource recreation
  * **Warning:** Can cause downtime
* RETRY
  * Tiempo de intentos