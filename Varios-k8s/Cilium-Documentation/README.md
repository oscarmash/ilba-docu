# Index:

* [Documentación variada](#id1) :shit:
* [Architecture](#id10) :two::zero:%
* [Network Policy](#id20) :one::eight:%
* [Service Mesh](#id30) :one::six:%
* [Network Observability](#id40) :one::zero:%
* [Installation and Configuration](#id50) :one::zero:%
* [Cluster Mesh](#id60) :one::zero:%
* [eBPF](#id70) :one::zero:%
* [BGP and External Networking](#id80) :zero::six:%

# Documentación variada :shit: <div id='id1' />

Notas generales:
* URL de LABS: https://isovalent.com/resource-library/labs/
* Por defecto viene con un [ingress](https://docs.cilium.io/en/stable/network/servicemesh/ingress/) y un sistema de asignación de IP's ( [LB IPAM](https://docs.cilium.io/en/stable/network/lb-ipam/) )
* Cilium is an open source, cloud native solution for providing, securing, and observing network connectivity between workloads
* No usa iptables, usa eBPF (recuerda que iptable cuesta de escalar)
* While traditional firewalls operate at Layers 3 and 4, Cilium can also secure modern Layer 7 application protocols such as REST/HTTP, gRPC, and Kafka (in addition to enforcing at Layers 3 and 4)
  * Allow all HTTP requests with method GET and path /public/.*. Deny all other requests.
  * Require the HTTP header X-Token: [0-9]+ to be present in all REST calls.
* For all network processing including protocols such as IP, TCP, and UDP, Cilium uses eBPF as the highly efficient in-kernel datapath. Protocols at the application layer such as HTTP, Kafka, gRPC, and DNS are parsed using a proxy such as Envoy.

Cilium Capabilities:
* Networking
  * Overlay (by default)
  * Native routing
* Cilium supports simple-to-configure transparent encryption, using IPSec or WireGuard, that when enabled, secures traffic between nodes without requiring reconfiguring any workload
* Load Balancing: implements distributed load balancing for traffic between application containers and external services (fully replace components such as kube-proxy)
* Network Observability: Cilium includes a dedicated network observability component called Hubble.
  * Visibility into network traffic at Layer 3/4 (IP address and port) and Layer 7 (API Protocol).
  * Event monitoring with metadata: When a packet is dropped, the tool reports not only the source and destination IP but also the full label information of both the sender and receiver, among other information.
  * Configurable Prometheus metrics exports.
  * A graphical UI to visualize the network traffic flowing through your clusters.

Test:
* You are configuring CIDR-based policies in Cilium and need to assign a minimum valid security identity for a CIDR identity. What is the minimum value you should use?
  * 16777217 -> Represents 2^24 +1, which is the minimum valid value for CIDR-based security identities.
* What is the valid range for security identities in Cilium?
  * 1 to 2^32 -1
* What mechanism does the Cilium Operator use to garbage collect stale security identities in CRD Identity allocation mode?
  * The operator periodically scans its local cache for identities that haven't received recent heartbeats and deletes them to free up resources.
* What advantage does Cilium Cluster Mesh provide by enabling shared services across multiple clusters?
  * It enables sharing of services like secrets management, logging, monitoring, or DNS between all clusters
* Which advantage does routing outbound traffic through a Cilium egress gateway node provide?
  * Routing outbound traffic through an egress gateway node ensures that the traffic appears from a stable and predictable IP address, which is beneficial for external systems.
* What are the prerequisites for enabling Cilium's egress gateway feature in a Kubernetes cluster?
  * Operators must provision network-facing interfaces and IP addresses on gateway nodes for the egress gateway to function correctly.
* Which of the following data stores is used by default in Cilium to propagate state between agents?
  * Kubernetes CRDs are the default data store for state propagation in Cilium.
* What type of metrics can Hubble provide regarding HTTP response codes in a Kubernetes cluster?
  * Hubble can provide the rate of 5xx or 4xx HTTP response codes for individual services or across clusters.
* After enabling IPsec encryption using the Cilium CLI, you observe that some traffic is not being encrypted. What could be a possible reason based on the configuration guidelines?
  * Traffic destined to the same node is not encrypted by design, as there is no benefit in encrypting local traffic.
* Your organization is transitioning from using the Kubernetes Ingress API to the Gateway API with Cilium to manage ingress traffic. You currently have Ingress resources with vendor-specific annotations. Which tool can assist in migrating these Ingress configurations to the Gateway API, and what is its current status?
  * The Ingress2Gateway tool is experimental and can accurately convert simple Ingress resources to Gateway API resources.
* You are deploying Cilium in a private cloud and want to reserve the first and last IP addresses of each CIDR block in your IP Pools to prevent potential network conflicts. Which configuration change should you make to your IP Pool specification?
  * If you wish to reserve the first and last IPs of CIDRs, you can set the .spec.allowFirstLastIPs field to No
* After successfully installing Cilium using the Cilium CLI, you want to run only the network performance tests between specific nodes labeled for performance testing. Which command and options should you use?
  * Using 'cilium connectivity perf' with the '--node-selector perf-test=true' correctly targets specific labeled nodes.
* You have an existing Kubernetes cluster using Calico as its default CNI plugin. You want to leverage Hubble for enhanced network observability without replacing Calico. Which Cilium installation option should you use?
  * --set cni.chainingMode=generic-veth correctly specifies the generic veth chaining mode compatible with Calico.
* How does eBPF ensure that injected programs do not compromise the stability and security of the Linux kernel?
  * eBPF programs are verified by the kernel to ensure they are safe and do not contain unsafe operations before they are executed.
* How can Hubble assist in proactively addressing issues before they impact users by utilizing performance data?
  * Generating performance metrics and setting up alerts allows teams to monitor key indicators like latency and error rates, and address issues before they affect users.
* After enabling Hubble redaction in your Cilium setup, you notice that HTTP query parameters are no longer visible in your observability reports. Which configuration option is responsible for this behavior?
  * --hubble-redact-http-urlquery
* How does the Gateway API improve the portability of configurations compared to the traditional Ingress API?
  * Removing vendor-specific annotations allows Gateway API resources to be more portable across different implementations.
* Which eBPF programs are used by Constellation’s solution to filter unencrypted pod-to-pod traffic for VXLAN and direct routing, respectively?
  * bpf_overlay is used for VXLAN, and bpf_host is used for direct routing.
* How does Cilium’s Gateway API implementation enhance protocol support beyond the traditional Ingress API?
  * Cilium enhances protocol support by extending beyond HTTP and HTTPS to include TCP, UDP, and gRPC, allowing for more versatile traffic management.
* You are managing a multi-team Kubernetes cluster and want to migrate from Ingress to Gateway API to allow different teams to manage their routes without affecting each other. Which Gateway API feature best supports this requirement?
  * Role-based personas with specific access to Gateway API objects allow different teams to manage their routes independently without interfering with each other.
* Which cilium-dbg subcommand is used to manage and retrieve information about network endpoints?
  * cilium-dbg endpoint
* Which flag would you use with a cilium-dbg command to output the results in JSONPath format?
  * '-o jsonpath='{...}'' correctly uses the '-o' flag to specify JSONPath output.
* How does the Endpoint Policy object in Cilium enforce network policies?
  * By using a map to lookup packet identities and applying corresponding L3/L4 policies.
* You have added an external workload named 'runtime' to your Cilium-managed Kubernetes cluster and executed the installation script on the external VM. However, when you check the CEW status, the IP address for 'runtime' is still showing as N/A. What is the most likely reason?
  * If the hostname does not match the CEW resource name, the workload may not successfully join the cluster, resulting in an IP of N/A.
* What capability of Hubble enables teams to identify potential security threats by monitoring unusual traffic patterns and detecting anomalies in real-time?
  * Security-focused observability
* How does eBPF enhance system performance in comparison to traditional kernel modules?
  * eBPF runs programs directly in the kernel, minimizing the need to move data between user space and kernel space, which enhances performance.
  * By avoiding the overhead of transferring data between user space and kernel space.
* Your organization is transitioning from using multiple Ingress Controllers with vendor-specific annotations to the Gateway API with Cilium. The current setup causes inconsistencies and management challenges. What is a key advantage of adopting the Gateway API in this scenario?
  * It centralizes traffic management and reduces dependency on annotations.
* What limitation is associated with using DNS-based Layer 3 policies in Cilium?
  * DNS-based policies require a proxy to handle DNS traffic.
  * DNS-based policies rely on a proxy to convert DNS names to IPs and respect DNS TTLs.
* Which IPAM mode in Cilium supports dynamic CIDR/IP allocation?
  * Multi-Pool
* What is a prerequisite for external workloads to have IP connectivity with the nodes in a Cilium-managed Kubernetes cluster?
  * External workloads must run in the same cloud provider virtual network or establish peering/VPN tunnels with the cluster nodes.
* You have a Pod selected by multiple policies in Cilium, including both Allow and Deny policies. A traffic attempt is made on a port where both an Allow and a Deny policy are present. What will be the outcome of this traffic attempt?
  * The traffic will be denied due to the Deny policy.
  * Deny policies take precedence and will block the traffic regardless of Allow policies.
* You have deployed Cilium's egress gateway in your Kubernetes cluster on AWS. However, some pod-to-pod traffic is exiting the cluster with the pod's own IP instead of the egress gateway's IP. What is the most likely cause based on Cilium's configuration guidelines?
  * There is a known delay before egress gateway policies are applied to newly created pods, causing some traffic to bypass the gateway initially.
  * There is a delay before egress gateway policies are enforced on new pods.
* How does Cilium enhance standard Kubernetes network policies?
  * By adding support for Layer 7 policies, allowing application-level controls.
* How does the Cilium Operator achieve high availability (HA) within a Kubernetes cluster?
  * By running multiple replicas and using Kubernetes leader election with lease locks.
* If you encounter IP allocation errors in Cilium's Cluster Scope IPAM mode, which Kubernetes command can you use to check the operator status?
  * kubectl get ciliumnodes -o jsonpath='{range .items[*]}{.metadata.name} {.status.ipam.operator-status} {end}'
  * This command retrieves the operator status field in the CiliumNode resources, which is essential for diagnosing IP allocation errors.
* Which of the following fields can be used to match HTTP requests in Cilium's Layer 7 policies?
  * Path, Method, Host, Headers
* Which of the following best describes the structure of a Cilium network policy rule?
  * Each rule can contain both ingress and egress sections.

# Architecture <div id='id10' />

* Components
  * Cilium Agent
    * is responsible for managing the network policies in Cilium
    * enforce network policies and manage networking for pods
    * runs on every node in the cluster
  * Cilium Operator
    * Handles lifecycle management of Cilium components
    * clusters can generally function when the operator becomes unavailable
  * Hubble
    * provides visibility into network traffic and performance metrics in Cilium
  * Cluster Mesh
    * Connecting multiple Kubernetes clusters
  * Service Mesh
    * Traffic management between services
    * Layer 7
  * Datapath
    * The method of routing packets through the network stack

# Network Policy <div id='id20' />

Network policies, Cilium can enforce both:

* Native Kubernetes NetworkPolicies (only L3 and L4)
* Enhanced CiliumNetworkPolicy (L3, L4 and L7)
  * CiliumNetworkPolicy
  * CiliumClusterwideNetworkPolicy

Overview of Network Policy:

* [Layer 3](https://docs.cilium.io/en/latest/security/policy/language/#layer-3-examples)
  * fromEndpoints
  * toEndpoints
  * fromRequires (separation of concern)
  * toServices
    * k8sService
    * k8sServiceSelector
  * toEntities
    * kube-apiserver
    * host
    * remote-node
    * world
  * fromNodes
  * toCIDR
  * toFQDNs
* [Layer 4](https://docs.cilium.io/en/latest/security/policy/language/#layer-4-examples)
  * toPorts
  * icmps
* [Layer 7](https://docs.cilium.io/en/latest/security/policy/language/#layer-7-examples)
  * HTTP
  * Kafka
  * DNS Policy and IP Discovery

Example NetworkPolicy:

![alt text](images/NetwrokPolicy.png)

# Service Mesh <div id='id30' />

* Kubernetes Ingress
  * Cilium Ingress
  * Gateway API
    * Replacement for Kubernetes Ingress
* Encryption in transit
  * IPSec
  * WireGuard
    * Faster than IPSec
* Mutual Authentication (mTLS)
* L7-Aware traffic management
* Que es el SPIRE ¿?

# Installation and Configuration <div id='id50' />

Tenemos dos formas de instalar Cilium:

* Cilium CLI tool
* Helm chart (esta es la que hemos usado y es la que recomienda Cilium)

# Cluster Mesh <div id='id60' />

Cluster Mesh capabilities make it easy for workloads to communicate with services hosted in different Kubernetes clusters.

* Setup
  * Specify Cluster Name and ID
  * Shared CA
  * Enable Cluster Mesh
  * Connect Clusters
  * Test pod connectivity between clusters

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

# BGP and External Networking <div id='id80' />

## BGP

* BGP
  * iBGP vs eBGP
  * TCP 179
  * bgpControlPlane: enabled: true
  * Graceful restart
  * BGP use OSPF for establishing egress connectivity
  * Command used to verify BGP peer status in a router: *show ip bgp summary*

Example CiliumBGPPeeringPolicy:

![alt text](images/CiliumBGPPeeringPolicy.png)

## External Networking

* External Networking ¿?
* External Networking - VTEP Integration ¿?
  * Use VXLAN
* Egress Networking ¿?
* Cilium-managed clusters ¿?