---
tags: [cka/networking, networking]
aliases: [Linux Network Namespace, netns, network isolation]
---

# Network Namespaces

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Pods]], [[Services]], [[kube-proxy]], [[Cluster Architecture]]

## Overview

A **Network Namespace** is a Linux kernel feature that provides **isolated network environments** within a single host. Each namespace has its own independent network interfaces, IP addresses, routing table, firewall rules, and DNS configuration. This is the fundamental mechanism that gives each Kubernetes [[Pods|Pod]] its own unique IP address.

## What Gets Isolated

| Component | Isolated per Namespace |
|---|---|
| Network interfaces | ✅ Yes |
| IP addresses | ✅ Yes |
| Routing table | ✅ Yes |
| ARP table | ✅ Yes |
| Firewall rules (iptables) | ✅ Yes |
| Port bindings | ✅ Yes |
| Loopback device | ✅ Yes |

## Relationship to Containers and Pods

- Every **Pod** in Kubernetes gets its own network namespace
- All **containers within a Pod** share the same network namespace (that's how they communicate via `localhost`)
- The network namespace gives each Pod a unique IP
- CNI plugins wire these namespaces together to enable Pod-to-Pod communication

```
Node
├── Pod A namespace (IP: 10.244.1.5)
│   ├── container-1 (shares namespace)
│   └── container-2 (shares namespace)
└── Pod B namespace (IP: 10.244.1.6)
    └── container-1
```

## Linux Commands for Network Namespaces

```bash
# Create a network namespace
ip netns add ns1

# List namespaces
ip netns list

# Delete a namespace
ip netns delete ns1

# Run commands inside a namespace
ip netns exec ns1 ip addr
ip netns exec ns1 ping 8.8.8.8
ip netns exec ns1 ip route
```

## Connecting Namespaces with veth Pairs

Virtual ethernet (veth) pairs act like a virtual cable connecting two namespaces:

```bash
# Create veth pair
ip link add veth-host type veth peer name veth-ns

# Move one end into the namespace
ip link set veth-ns netns ns1

# Configure host end
ip addr add 10.0.0.1/24 dev veth-host
ip link set veth-host up

# Configure namespace end
ip netns exec ns1 ip addr add 10.0.0.2/24 dev veth-ns
ip netns exec ns1 ip link set veth-ns up
ip netns exec ns1 ip link set lo up

# Test connectivity
ip netns exec ns1 ping 10.0.0.1
```

## How CNI Uses Network Namespaces

When a Pod is created:

```
1. Container runtime creates a new network namespace for the Pod
2. kubelet calls CNI plugin with namespace info
3. CNI plugin:
   - Creates veth pair
   - Places one end in Pod namespace
   - Places other end in host/bridge
   - Assigns IP to Pod namespace
   - Sets up routing
4. Pod has unique IP; can communicate with other Pods
```

## Key Commands

```bash
# Check network namespaces on a node (SSH to node)
ip netns list

# View interfaces inside a Pod's namespace
# (done via container runtime, not directly)
kubectl exec -it <pod> -- ip addr
kubectl exec -it <pod> -- ip route
kubectl exec -it <pod> -- netstat -tulpn
```

## Common Issues / Troubleshooting

- **Pod can't reach other Pods** → CNI not configured correctly; check CNI pod logs
- **Pod has no IP** → CNI failed to assign; check CNI plugin pod status in kube-system
- **Port conflict** → two containers in same Pod can't bind same port (shared namespace)
- **Cross-node communication fails** → CNI overlay network issue; check routing between nodes

## Related Notes

- [[Pods]] — Each Pod gets its own network namespace
- [[kube-proxy]] — Programs iptables within the host network namespace
- [[Network Policy]] — CNI enforces policies using namespace-level filtering
- [[Cluster Architecture]] — Networking model built on top of Linux namespaces

## Key Mental Model

Network Namespaces are **invisible walls** that give each Pod its own private network stack. CNI plugins then build **bridges and tunnels** between these walls so Pods can reach each other. [[kube-proxy]] handles the virtual IP magic on top. Without network namespaces, every process on a node would share a single network — chaos.
