## **Overview**

kube-proxy runs on **every worker node** and maintains network rules to allow **Pods to communicate with each other and with Services**. It abstracts cluster networking so Services have a **stable virtual IP**, independent of Pod lifecycle.

It does **not** schedule Pods or make cluster decisions; it only programs packet routing on the node.

## Modes of Operation

### 1. iptables Mode (default)

- Creates rules in Linux iptables
- Redirects Service traffic to healthy Pods
- Scales well for large clusters
- Works without a userspace proxy process

### 2. IPVS Mode

- Uses Linux IP Virtual Server (IPVS) kernel module
- Higher performance and scalability
- Maintains persistent connection tracking
- Supports multiple load-balancing algorithms

### 3. Userspace Mode (deprecated)

- Runs a userspace proxy process
- Handles traffic in user space
- Only for legacy clusters

  

## Responsibilities

- Service VIP maintenance
- Endpoint updates
- Load balancing traffic across Pods
- Handles NodePort and ClusterIP routing
- Works with kube-apiserver to watch Endpoints

## Interaction with Control Plane

- Watches [[kube-apiserver]] for:
    - Services
    - Endpoints / EndpointSlices
- Updates node-level rules
- Does **not** talk to kubelet directly
- No direct access to etcd

## Configuration
### Deployment

- Runs as a DaemonSet on all nodes
    kube-proxy DaemonSet usually in kube-system namespace

### Important Flags

- --cluster-cidr
- --masquerade-all
- --proxy-mode (iptables, ipvs)
- --kubeconfig
- --hostname-override
- --healthz-bind-address

## **Monitoring and Health**

- Health endpoint: /healthz
- Metrics endpoint: /metrics
- Key metrics:
    - kubeproxy_sync_proxy_rules_duration_seconds
    - kubeproxy_iptables_sync_total    
    - kubeproxy_ipvs_sync_total

## Troubleshooting

- Service unreachable → check iptables/IPVS rules    
- Pod traffic fails → check Endpoints and kube-proxy logs
- High CPU → iptables/ipvs sync interval too low, or large cluster