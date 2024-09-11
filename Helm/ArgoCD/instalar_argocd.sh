#!/bin/bash

VERSION_FLUX="1.11.4"
VERSION_HELM_OPERATOR="1.4.2"
REPO_GIT="git@gitlab.ilba.cat:fluxcd/kubespray.git"
REPO_BRANCH="master"
WORK_FOLDER="namespaces"

CYAN='\033[0;36m'
NC='\033[0m'


echo -e "${CYAN}Instalar NFS client ${NC}"
for i in {3..5};do
    ssh root@172.26.0.3$i -C "apt-get update && apt install -y nfs-common"
done   
ssh root@172.26.0.80 -C "apt-get update && apt install -y nfs-common"

echo -e "${CYAN}Nos conectamos al cluster de: mi-casa-debian ${NC}"
kubectl ctx mi-casa-debian

echo -e "${CYAN}Nos conectamos al namespace: default ${NC}"
kubectl ns default

echo -e "${CYAN}Configuración de DNS ${NC}"
kubectl apply -f custom/dns-configmap.yaml

echo -e "${CYAN}Creamos el namsepace: argocd ${NC}"
kubectl apply -f custom/namespace-argocd.yaml

echo -e "${CYAN}Instalamos metallb ${NC}"
helm install \
metallb metallb/metallb \
--create-namespace \
--namespace metallb-system \
--version=0.13.3

echo -e "${CYAN}Esperamos a que arranquen todos los contenedores de MetalLB ${NC}"
kubectl wait --for=condition=Ready pods --all -n metallb-system --timeout=120s

echo -e "${CYAN}Aplicamos el rango de IP's para MetalLB (a partir de la versión 0.13) ${NC}"
kubectl delete validatingwebhookconfigurations.admissionregistration.k8s.io validating-webhook-configuration
kubectl apply -f custom/helm-metallb/values.yaml

echo -e "${CYAN}Instalamos ingress-nginx ${NC}"
helm install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace ingress-nginx \
--version=4.2.0 \
-f custom/helm-ingress-nginx/values.yaml

echo -e "${CYAN}Esperamos a que arranquen todos los contenedores de NGINX ${NC}"
kubectl wait --for=condition=Ready pods --all -n ingress-nginx --timeout=120s

# echo -e "${CYAN}Instalamos cert-manager ${NC}"
# helm install \
# cert-manager jetstack/cert-manager \
# --namespace cert-manager \
# --set installCRDs=true \
# --create-namespace \
# --version=v1.7.1

# echo -e "${CYAN}Configuración de cert-manager ${NC}"
# kubectl apply -f custom/helm-cert-manager/00-clusterissuer.yaml

echo -e "${CYAN}Instalamos ArgoCD ${NC}"
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo -e "${CYAN}Esperamos a que arranquen todos los contenedores de ArgoCD ${NC}"
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=240s

echo -e "${CYAN}ArgoCD como LoadBalancer ${NC}"
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

echo -e "${CYAN}Configuración de GIT y clave SSH de ArgoCD ${NC}"
kubectl apply -f applications/00-secret-configmap.yaml

echo -e "${CYAN}Password de acceso ${NC}"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

echo -e "${CYAN}Add knownhosts key in ArgoCD ${NC}"
echo -e "${CYAN}Username: admin ${NC}"
echo -e "${CYAN}Password: el que hay arriba ${NC}"
argocd --insecure login 172.26.0.102:443
ssh-keyscan gitlab.ilba.cat | argocd cert add-ssh --batch

echo -e "${CYAN}ArgoCD -> Creamos project Ilba ${NC}"
kubectl apply -f applications/05-project-ilba.yaml

echo -e "${CYAN}ArgoCD -> Desplegamos Homer ${NC}"
kubectl apply -f applications/app-homer.yaml

echo -e "${CYAN}ArgoCD -> Desplegamos Guacamole ${NC}"
kubectl apply -f applications/app-guacamole.yaml

echo -e "${CYAN}ArgoCD -> Desplegamos Plex ${NC}"
kubectl apply -f applications/app-plex.yaml

echo -e "${CYAN}ArgoCD -> Desplegamos nfs-subdir-external-provisioner ${NC}"
kubectl apply -f helm/nfs-subdir-external-provisioner.yaml

# echo -e "${CYAN}ArgoCD -> Desplegamos kube-prometheus-stack ${NC}"
# kubectl apply -f helm/kube-prometheus-stack.yaml
