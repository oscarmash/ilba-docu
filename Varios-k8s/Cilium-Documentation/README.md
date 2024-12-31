# Index:

* [Documentación](#id10)


# Documentación variada <div id='id10' />

Notas generales:
* Por defecto viene con un [ingress](https://docs.cilium.io/en/stable/network/servicemesh/ingress/) y un sistema de asignación de IP's ( [LB IPAM](https://docs.cilium.io/en/stable/network/lb-ipam/) )
* Cilium is an open source, cloud native solution for providing, securing, and observing network connectivity between workloads
* No usa iptables, usa eBPF (recuerda que iptable cuesta de escalar)
* While traditional firewalls operate at Layers 3 and 4, Cilium can also secure modern Layer 7 application protocols such as REST/HTTP, gRPC, and Kafka (in addition to enforcing at Layers 3 and 4)
  * Allow all HTTP requests with method GET and path /public/.*. Deny all other requests.
  * Require the HTTP header X-Token: [0-9]+ to be present in all REST calls.

Cilium Capabilities:
* Networking
  * Overlay (by default)
  * Native routing
* Network policies, Cilium can enforce both:
  * Native Kubernetes NetworkPolicies (only L3 and L4)
  * Enhanced CiliumNetworkPolicy (L3, L4 and L7)
    * CiliumNetworkPolicy
    * CiliumClusterwideNetworkPolicy
* Cilium supports simple-to-configure transparent encryption, using IPSec or WireGuard, that when enabled, secures traffic between nodes without requiring reconfiguring any workload
* Cluster Mesh capabilities make it easy for workloads to communicate with services hosted in different Kubernetes clusters.
* Load Balancing: implements distributed load balancing for traffic between application containers and external services (fully replace components such as kube-proxy)
* Network Observability: Cilium includes a dedicated network observability component called Hubble.
  * Visibility into network traffic at Layer 3/4 (IP address and port) and Layer 7 (API Protocol).
  * Event monitoring with metadata: When a packet is dropped, the tool reports not only the source and destination IP but also the full label information of both the sender and receiver, among other information.
  * Configurable Prometheus metrics exports.
  * A graphical UI to visualize the network traffic flowing through your clusters.

Notas de Cluster Mesh:
* Requirements:
  * All Kubernetes worker nodes must be assigned a unique IP address, and all worker nodes must have IP connectivity between each other
  * All clusters must be assigned unique PodCIDR ranges to prevent pod IP addresses from overlapping across the mesh.
* Architecture:
  * Access to the Cluster Mesh API Servers running in each cluster is protected using TLS certificates.
  * State from multiple clusters is never mixed. Access from one cluster into another is always read-only. This ensures that the failure domain remains unchanged, i.e. failures in one cluster never propagate into other clusters
* Global Services:
  * Establishing service load-balancing between clusters is achieved by defining a Kubernetes service with an identical name and namespace in each cluster and adding the annotation service.cilium.io/global: "true" to declare it as a global service. Cilium agents will watch for this annotation and if it's set to true, will automatically perform load-balancing to the corresponding service endpoint pods located across clusters.
  * You can control this global load-balancing further by setting the annotation service.cilium.io/shared: to true/false in the service definition in different clusters, to explicitly include or exclude a particular cluster’s service from being included in the multi-cluster load-balancing. By default, setting service.cilium.io/global: "true" implies service.cilium.io/shared: "true" if it's not explicitly set.
  * In some cases, load-balancing across multiple clusters might not be ideal. The annotation service.cilium.io/affinity: "local|remote|none" can be used to specify the preferred endpoint destination.

Tenemos dos formas de instalar Cilium:

* Cilium CLI tool
* Helm chart (esta es la que hemos usado y es la que recomienda Cilium)
