---
tags: [cka/architecture, architecture]
aliases: [Kubernetes Architecture, Cluster Overview]
---

# Cluster Architecture

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[etcd]], [[kube-scheduler]], [[kube-controller-manager]], [[kubelet]], [[kube-proxy]]

## Overview

Kubernetes follows a **control plane + worker node** architecture. The control plane makes global decisions and stores cluster state, while worker nodes run application workloads. All communication is API-driven, with [[kube-apiserver]] as the central hub.

The design is declarative: users define _desired state_, and the system continuously reconciles reality to match it.

## Control Plane Components

| Component | Role |
|---|---|
| [[kube-apiserver]] | Single entry point for all operations; authenticates, authorizes, validates |
| [[etcd]] | Distributed key-value store; source of truth for cluster state |
| [[kube-scheduler]] | Watches unscheduled [[Pods]], selects optimal Node |
| [[kube-controller-manager]] | Runs reconciliation loops; moves cluster toward desired state |

All components talk **to** [[kube-apiserver]], not to each other. The apiserver is a **chokepoint by design**.

### cloud-controller-manager

Integrates with cloud provider APIs and manages:
- Nodes
- Load balancers
- Routes
- Volumes

Decouples cloud logic from core Kubernetes.

## Worker Node Components

| Component | Role |
|---|---|
| [[kubelet]] | Node-level agent; ensures assigned Pods run and are healthy |
| [[kube-proxy]] | Implements Service networking; programs iptables/IPVS rules |
| Container Runtime | Pulls images and runs containers (containerd, CRI-O) |

## Communication Flow

```
Users → kube-apiserver (kubectl, controllers, operators)
Control plane components → kube-apiserver
kubelet → kube-apiserver (watch + report)
kube-apiserver → etcd (only component that writes to etcd)
```

## Cluster Networking Model

- Every [[Pods|Pod]] gets a unique IP
- Pods can reach each other without NAT
- [[Services]] provide stable virtual IPs
- Implemented via CNI plugins

Networking responsibilities are split:
- CNI → Pod networking
- [[kube-proxy]] → Service abstraction

## High Availability Architecture

### Control Plane HA

- Multiple [[kube-apiserver]] instances behind load balancer
- [[etcd]] runs as a quorum (odd number of members: 3 or 5)
- [[kube-scheduler]] and [[kube-controller-manager]] use leader election

### Worker Node Scaling

- Nodes can be added or removed dynamically
- Workloads rescheduled automatically on failure

## Failure Domains

| Failure | Response |
|---|---|
| Pod failure | [[kubelet]] + controllers react |
| Node failure | Node Controller evicts Pods |
| Control plane component failure | HA replicas take over |
| etcd failure | Cluster becomes read-only or unavailable (critical) |

## Design Principles

- Declarative configuration
- Level-based reconciliation (not edge-triggered)
- Loose coupling via API
- Replaceable implementations (CNI, CSI, CRI)
- Expect failure; recover continuously

## Key Commands

```bash
# Check component health
kubectl get componentstatuses

# View all nodes
kubectl get nodes -o wide

# Inspect control plane pods
kubectl get pods -n kube-system

# Describe a node
kubectl describe node <node-name>
```

## Common Issues / Troubleshooting

- Control plane Pods not running → check [[Static Pods]] manifests in `/etc/kubernetes/manifests/`
- Node NotReady → check [[kubelet]] status: `systemctl status kubelet`
- etcd unreachable → cluster becomes read-only; check certificates and endpoints
- Scheduler not working → Pods stuck Pending; check scheduler logs

## Related Notes

- [[kube-apiserver]] — The hub all components talk through
- [[etcd]] — Where all state is stored
- [[Static Pods]] — How control plane components run
- [[kubeadm]] — Tool for bootstrapping this architecture
- [[Backup]] — Protecting etcd state

## Key Mental Model

Kubernetes is a **control loop machine**. Each component watches a slice of state through [[kube-apiserver]] and works to make reality match the desired spec. Remove any component and that slice of reconciliation stops — but the rest of the cluster keeps running.
