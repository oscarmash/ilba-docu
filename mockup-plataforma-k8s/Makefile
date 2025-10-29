SHELL := /bin/bash
PATH := bin:$(PATH)
ENV ?= k8s-test
KUBESPRAY_VERSION=v2.29.0
KUBE_VERSION ?= 1.33.5
TAG := xxx

BIN=docker run --rm -it --name kubespray --hostname kubespray \
	--mount type=bind,source="${HOME}"/.ansible/roles/,dst=/ilimit/roles/ \
	--mount type=bind,source="${HOME}"/.ssh/id_rsa,dst=/root/.ssh/id_rsa \
	--mount type=bind,source="${HOME}"/.ssh/known_hosts,dst=/root/.ssh/known_hosts \
	--mount type=bind,source="$(PWD)/cluster-apps",dst=/kubespray/cluster-apps \
	--mount type=bind,source="$(PWD)/inventory",dst=/kubespray/inventory \
	--mount type=bind,source="$(PWD)/playbooks_custom",dst=/kubespray/playbooks_custom \
	-v "$(PWD)/cluster.yml:/kubespray/cluster.yml" \
	-v "$(PWD)/variables_kubespray.yml:/kubespray/variables_kubespray.yml" \
	quay.io/kubespray/kubespray:$(KUBESPRAY_VERSION)

shell:
	$(BIN) bash

install_all:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini cluster.yml -e kube_version=$(KUBE_VERSION) -b

upgrade_kubespray:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks/upgrade_cluster.yml --skip-tags=multus -e kube_version=$(KUBE_VERSION) -e upgrade_cluster_setup=true -e "@variables_kubespray.yml" -b -l $(NODE)

########################

pre_install:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks_custom/pre_install.yaml -b

install_kubespray:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks/cluster.yml -e kube_version=$(KUBE_VERSION) -e "@variables_kubespray.yml" -b

post_install:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks_custom/post_install.yaml -b

install_applications:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks_custom/install_applications.yaml -e cluster_name=$(ENV)

install_applications_tag:
	$(BIN) ansible-playbook -i inventory/$(ENV)/inventory.ini playbooks_custom/install_applications.yaml -e cluster_name=$(ENV) -t $(TAG)

########################
