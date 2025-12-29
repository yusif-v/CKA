## Overview

Kubernetes follows a **control plane + worker node** architecture. The control plane makes global decisions and stores cluster state, while worker nodes run application workloads. All communication is API-driven, with the **kube-apiserver as the central hub**.

The design is declarative: users define _desired state_, and the system continuously works to make reality match it.

## High-Level Components

### Control Plane

Responsible for cluster-wide state, scheduling, and reconciliation.

- [[kube-apiserver]]    
- [[etcd]]
- [[kube-scheduler]]
- [[kube-controller-manager]]
- [[cloud-controller-manager]] 

### Worker Nodes

Responsible for running Pods and reporting status.

- [[kubelet]]
- [[kube-proxy]]
- [[Container Runtime]]

## Control Plane Architecture

### kube-apiserver (Hub)

- Single entry point for all operations
- Authenticates, authorizes, validates requests
- Persists state to etcd
- Serves watches and cached data

All components talk **to the apiserver**, not to each other.

### etcd (State Store)

- Distributed key-value store
- Source of truth for cluster state
- Stores:
    - Pods, Nodes, Services
    - ConfigMaps, Secrets
    - RBAC, CRDs
- Requires strong consistency (Raft)

### kube-scheduler

- Watches for unscheduled Pods
- Selects optimal Node
- Writes binding decision back to apiserver

### kube-controller-manager

- Runs reconciliation loops
- Moves cluster toward desired state
- Reacts to changes, failures, deletions

### cloud-controller-manager

- Integrates with cloud provider APIs
- Manages:
    - Nodes
    - Load balancers
    - Routes
    - Volumes
- Decouples cloud logic from core Kubernetes

## Worker Node Architecture
### kubelet

- Node-level agent
- Watches for assigned Pods
- Talks to container runtime
- Reports Pod and Node status

### Container Runtime

- Pulls images
- Creates and runs containers
- Examples:    
    - containerd 
    - CRI-O

### kube-proxy

- Implements Service networking
- Programs iptables / IPVS rules
- Enables stable virtual IPs for Services

## Communication Flow

- Users → kube-apiserver (kubectl, controllers, operators)
- Control plane components → kube-apiserver
- kubelet → kube-apiserver (watch + report)
- No component writes directly to etcd except kube-apiserver

The apiserver is a **chokepoint by design**.

## Cluster Networking Model

- Every Pod gets a unique IP
- Pods can reach each other without NAT
- Services provide stable virtual IPs
- Implemented via CNI plugins

Networking responsibilities are split:
- CNI → Pod networking
- kube-proxy → Service abstraction

## High Availability Architecture
### Control Plane HA

- Multiple kube-apiserver instances behind load balancer
- etcd runs as a quorum (odd number of members)
- Scheduler and controller-manager use leader election

### Worker Node Scaling

- Nodes can be added or removed dynamically
- Workloads rescheduled automatically on failure

## Failure Domains

- Pod failure → kubelet + controllers react
- Node failure → Node Controller evicts Pods
- Control-plane component failure → HA replicas take over
- etcd failure → cluster becomes read-only or unavailable (critical)

## Design Principles

- Declarative configuration
- Level-based reconciliation
- Loose coupling via API
- Replaceable implementations (CNI, CSI, CRI)
- Expect failure, recover continuously