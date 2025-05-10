# Index:

* [Instalación de ArgoCD](#id10)

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
