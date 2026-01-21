# OS Upgrade
## Overview

An **OS Upgrade** in Kubernetes refers to safely upgrading the **operating system of worker nodes** without disrupting running workloads.

The core idea is simple:
**drain → upgrade → uncordon**

Kubernetes itself provides the mechanisms to do this **without downtime** (when workloads are configured correctly).

## Why OS Upgrades Matter

- Security patches
- Kernel updates
- Performance and stability improvements
- Compliance requirements

Kubernetes treats nodes as **replaceable cattle**, not precious pets.

## High-Level Upgrade Flow

1. Mark node as unschedulable
2. Evict Pods safely
3. Upgrade OS
4. Bring node back into the cluster

## Step 1: Cordon the Node

Prevent new Pods from being scheduled.

```bash
kubectl cordon node01
```

Node becomes **SchedulingDisabled**.

## Step 2: Drain the Node

Evict Pods and move workloads elsewhere.

```bash
kubectl drain node01 --ignore-daemonsets
```

Common flags:
- --ignore-daemonsets → DaemonSet Pods are not evicted
- --delete-emptydir-data → Removes emptyDir volumes

## Step 3: Upgrade the OS

This step is **outside Kubernetes**:
- SSH into node
- Apply OS updates
- Reboot if needed

Kubernetes does not manage OS upgrades directly.

## Step 4: Uncordon the Node

Allow scheduling again.

```bash
kubectl uncordon node01
```

Node re-enters the scheduling pool.

## DaemonSets During OS Upgrade

- DaemonSet Pods are **not drained**
- They automatically restart after reboot
- Used for logging, monitoring, networking

🔗 Related:
- [[Daemonsets]]

## Pod Disruption Budgets (PDB)

PDBs control **how many Pods can be unavailable** during disruptions.

If drain fails, check PDBs.

🔗 Related:
- [[Pod Disruption Budget]]
- [[Scheduling]]

## Observing Node Status

```bash
kubectl get nodes
kubectl describe node node01
```

## Common Issues

- Drain blocked by strict PDBs
- Pods using emptyDir without delete flag
- Single-replica Deployments causing downtime
- Stateful workloads not prepared for eviction

## Best Practices

- Always use **multiple replicas**
- Define **Pod Disruption Budgets**
- Test drain in staging
- Upgrade nodes **one at a time**
- Automate OS upgrades where possible

## Key Mental Model

An OS upgrade is a **controlled evacuation**:
- Cordon = close the gate
- Drain = move people safely
- Upgrade = renovate the building
- Uncordon = reopen for business

Kubernetes stays calm because **Pods are meant to move**.