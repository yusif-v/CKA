---
tags: [cka/architecture, operations, cka/troubleshooting]
aliases: [Node Upgrade, Node Drain, Cordon, Uncordon]
---

# OS Upgrade

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubelet]], [[DaemonSets]], [[Pods]], [[Scheduling]], [[kubeadm]]

## Overview

An **OS Upgrade** in Kubernetes refers to safely upgrading the **operating system of a Node** without disrupting running workloads. The workflow is: **cordon → drain → upgrade → uncordon**. Kubernetes treats nodes as replaceable cattle — workloads are designed to move.

> [!tip] Exam Tip
> `kubectl drain --ignore-daemonsets` is heavily tested. Know why `--ignore-daemonsets` is needed and what `--delete-emptydir-data` does.

## High-Level Workflow

```
1. Cordon   → Mark node unschedulable (no new pods)
2. Drain    → Evict existing pods safely
3. Upgrade  → Apply OS updates (outside Kubernetes)
4. Uncordon → Return node to service
```

## Step 1: Cordon the Node

Prevent new [[Pods]] from being scheduled on the node:

```bash
kubectl cordon node01
```

Node status becomes `Ready,SchedulingDisabled`. Existing Pods are **not affected yet**.

## Step 2: Drain the Node

Safely evict all Pods and reschedule them on other nodes:

```bash
kubectl drain node01 --ignore-daemonsets
```

### Drain Flags

| Flag | Purpose |
|---|---|
| `--ignore-daemonsets` | Don't evict [[DaemonSets]] pods (they'll restart on node return) |
| `--delete-emptydir-data` | Delete pods using emptyDir volumes (data lost) |
| `--force` | Evict unmanaged pods (no controller) |
| `--grace-period=0` | Immediate eviction |
| `--timeout=300s` | Wait up to 5 minutes for eviction |

> [!warning]
> `--ignore-daemonsets` is **required** when DaemonSet pods are running. Without it, drain fails.

### What Gets Evicted

- [[Deployments]] pods → rescheduled on other nodes
- [[DaemonSets]] pods → **skipped** (use `--ignore-daemonsets`)
- [[Static Pods]] → **cannot be evicted**
- Pods with `emptyDir` volumes → blocked unless `--delete-emptydir-data`

## Step 3: Upgrade the OS

This step is **outside Kubernetes** — SSH into the node and apply updates:

```bash
# Example: Ubuntu
apt-get update && apt-get upgrade -y
reboot

# Example: RHEL/CentOS
yum update -y
reboot
```

Kubernetes does **not** manage OS package upgrades.

## Step 4: Uncordon the Node

Allow new [[Pods]] to be scheduled on the node again:

```bash
kubectl uncordon node01
```

Node returns to `Ready` status. Pods are **not automatically moved back** — they stay where they were rescheduled.

## Kubernetes Version Upgrades (kubeadm)

When upgrading Kubernetes itself (not just the OS):

```bash
# 1. Upgrade kubeadm (on control plane node)
apt-get install kubeadm=1.30.0-00

# 2. Plan and apply upgrade
kubeadm upgrade plan
kubeadm upgrade apply v1.30.0

# 3. Drain control plane node
kubectl drain controlplane --ignore-daemonsets

# 4. Upgrade kubelet and kubectl
apt-get install kubelet=1.30.0-00 kubectl=1.30.0-00
systemctl daemon-reload
systemctl restart kubelet

# 5. Uncordon
kubectl uncordon controlplane

# 6. Repeat for worker nodes (drain, upgrade kubelet, uncordon)
```

> [!tip] Always upgrade **control plane first**, then worker nodes. One minor version at a time.

## Pod Disruption Budgets (PDB)

PDBs control how many Pods can be unavailable during disruptions:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2    # Or: maxUnavailable: 1
  selector:
    matchLabels:
      app: web
```

If drain violates a PDB, it will wait or fail. Check: `kubectl get pdb`

## Key Commands

```bash
# Cordon
kubectl cordon node01

# Drain (with common flags)
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data

# Uncordon
kubectl uncordon node01

# Check node status
kubectl get nodes

# Check what's running on a node before draining
kubectl get pods --field-selector spec.nodeName=node01

# Check PDBs that might block drain
kubectl get pdb

# After uncordon, verify node is schedulable
kubectl describe node node01 | grep -i taint
```

## Common Issues / Troubleshooting

- **Drain stuck** → PDB preventing eviction; `kubectl get pdb` and check `DISRUPTIONS ALLOWED`
- **Drain fails with "cannot delete DaemonSet pods"** → add `--ignore-daemonsets` flag
- **Drain fails with "cannot delete Pods not managed by ReplicationController"** → add `--force`
- **emptyDir blocks drain** → add `--delete-emptydir-data` (data will be lost)
- **Node won't uncordon** → check if any taints were added; `kubectl describe node node01`

## Related Notes

- [[kubelet]] — Runs as systemd service; restart after kubelet upgrade
- [[DaemonSets]] — Their pods are skipped during drain; restart automatically
- [[Scheduling]] — Cordoned nodes are excluded from scheduling
- [[kubeadm]] — Handles Kubernetes version upgrades
- [[Pods]] — Single-replica deployments cause downtime during drain

## Key Mental Model

An OS upgrade is a **controlled evacuation**: Cordon = close the gate. Drain = move people safely to other buildings. Upgrade = renovate the empty building. Uncordon = reopen. Kubernetes stays calm because **Pods are designed to move**.
