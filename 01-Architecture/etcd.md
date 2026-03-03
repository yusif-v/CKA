---
tags: [cka/architecture, architecture]
aliases: [etcd store, Kubernetes state store]
---

# etcd

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[Backup]], [[etcdctl]], [[etcdutl]], [[Static Pods]]

## Overview

**etcd** is a distributed, consistent key-value store used by Kubernetes to store **all cluster state**. Every object — [[Pods]], [[Deployments]], [[Secrets]], [[ConfigMap]]s — lives in etcd. If etcd is lost, the cluster loses its memory entirely.

> [!tip] Exam Tip
> etcd backup and restore commands are **heavily tested** on the CKA. Know them cold.

## Role in Kubernetes

- Stores desired and current state for all cluster objects
- Uses the **Raft** consensus algorithm for strong consistency
- Only [[kube-apiserver]] reads from and writes to etcd directly
- Acts as the single **source of truth**

```
kubectl → kube-apiserver → etcd
```

## Deployment in kubeadm Clusters

Runs as a [[Static Pods|Static Pod]] in `kube-system`:

```bash
# Manifest location
/etc/kubernetes/manifests/etcd.yaml

# Data directory
/var/lib/etcd

# TLS certificates
/etc/kubernetes/pki/etcd/
```

Ports:
- `2379` — client communication
- `2380` — peer-to-peer communication

## Backup (Snapshot)

> [!tip] Exam Tip
> This exact command pattern is tested on the exam. Memorize it.

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify the snapshot
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db
```

## Restore from Snapshot

```bash
# Step 1: Restore to a new data directory
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot.db \
  --data-dir=/var/lib/etcd-restored

# Step 2: Update etcd manifest to point to new data dir
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd-restored
# Also update the hostPath volume mount

# Step 3: etcd will restart automatically (static pod)
```

## High Availability etcd

- Must run with an **odd number of nodes** (3, 5, 7)
- Requires majority quorum to function: `(n/2) + 1`
- Loss of quorum → cluster becomes read-only or unavailable

| Members | Quorum | Fault Tolerance |
|---|---|---|
| 1 | 1 | 0 |
| 3 | 2 | 1 |
| 5 | 3 | 2 |

## Key Commands

```bash
# Set API version (always v3 for Kubernetes)
export ETCDCTL_API=3

# Check endpoint health
etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Check endpoint status (shows leader, DB size)
etcdctl endpoint status --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# View etcd pod
kubectl get pod etcd-<node> -n kube-system
kubectl describe pod etcd-<node> -n kube-system
```

## Common Issues / Troubleshooting

- **Disk full** → etcd stops accepting writes; cluster effectively breaks
- **Certificate expiry** → connectivity fails; check `/etc/kubernetes/pki/etcd/`
- **Network latency between members** → Raft elections fail; cluster unstable
- **Wrong `--data-dir` after restore** → etcd uses old data; update manifest carefully
- **No backup exists** → cluster is unrecoverable after data loss

## Related Notes

- [[etcdctl]] — Command-line client for etcd operations
- [[etcdutl]] — Offline tool for snapshot inspection and restore
- [[Backup]] — Full backup strategy including etcd
- [[kube-apiserver]] — Only component that communicates with etcd
- [[Static Pods]] — How etcd is deployed in kubeadm clusters
- [[TLS in Kubernetes]] — etcd uses mutual TLS

## Key Mental Model

etcd is **Kubernetes' brain**. You can replace limbs (Pods), regrow organs (Nodes), but if the brain is gone, **identity and memory vanish**. Protect etcd like your backups — because they are the same thing.
