# etcd
#architecture 
## Overview

**etcd** is a **distributed, consistent key-value store** used by Kubernetes to store **all cluster state**.

Every object in Kubernetes — Pods, Deployments, Secrets, ConfigMaps — ultimately lives in etcd.

If etcd is lost, the cluster loses its memory.

## Role in Kubernetes

- Stores desired and current state
- Stores configuration and metadata
- Provides strong consistency (Raft consensus)
- Acts as the **source of truth**

🔗 Related:
- [[kube-apiserver]]
- [[Backup]]

## Architecture Basics

- Uses the **Raft** consensus algorithm
- Typically runs as a **static Pod**
- Can be single-node or multi-node (HA)

All reads and writes go through:

```bash
kubectl → kube-apiserver → etcd
```

## etcd in a kubeadm Cluster

- Runs in kube-system
- Manifest:

```bash
/etc/kubernetes/manifests/etcd.yaml
```

- Data directory:

```bash
/var/lib/etcd
```

🔗 Related:
- [[Static Pods]]
- [[Manifests]]
- [[kubeadm]]

## Ports and Security

- Client port: **2379**
- Peer port: **2380**
- TLS enabled by default

Certificates:

```bash
/etc/kubernetes/pki/etcd/
```

## etcdctl

Command-line client for etcd.

Always use API v3:

```bash
export ETCDCTL_API=3
```

Check endpoint health:

```bash
etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

## etcd Backup (Snapshot)

```bash
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Verify snapshot:

```
ETCDCTL_API=3 etcdctl snapshot status snapshot.db
```

🔗 Related:
- [[Backup]]

## etcd Restore (High Level)

1. Stop etcd
2. Restore snapshot to new data directory
3. Update etcd manifest
4. Restart etcd

```bash
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

## High Availability etcd

- Odd number of nodes (3, 5)
- Requires majority quorum
- Loss of quorum = cluster read-only or unavailable

## Best Practices

- Use SSDs
- Back up regularly
- Secure with TLS
- Monitor disk latency
- Never access etcd directly except for backup/restore

## Common Pitfalls

- Running etcd without backups
- Disk full → cluster failure
- Certificate expiry
- Network latency between members

## Key Mental Model

etcd is **Kubernetes’ brain**.

You can replace limbs (Pods),
regrow organs (Nodes),
but if the brain is gone, **identity and memory vanish**.

Protect etcd like you protect your backups — because they are the same thing.