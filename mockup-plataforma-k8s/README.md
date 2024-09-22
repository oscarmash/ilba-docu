# Instalación de K8s

Pasos a seguir

* make pre_install
* make install_kubespray ENV=k8s-test KUBE_VERSION=v1.30.4
* make install_applications

# Dudas

Saber la versión de K8s que podemos instalar
```
$ make shell
root@kubespray:/kubespray# apt-get update && apt-get install less
root@kubespray:/kubespray# less roles/kubespray-defaults/defaults/main/checksums.yml
```

---

De la siguiente [web](https://quay.io/repository/kubespray/kubespray?tab=tags&tag=latest), sacamos la versión del: **KUBESPRAY_VERSION**

---

