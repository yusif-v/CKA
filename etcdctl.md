# etcdctl
## Overview

**etcdctl** is the **command-line client** for interacting with **etcd**.

In Kubernetes, etcdctl is mainly used for:
- Health checks
- Snapshots (backup)
- Restore operations
- Debugging etcd clusters

Direct data manipulation is **strongly discouraged**.

## API Version

Kubernetes uses **etcd API v3**.

Always set:

```bash
export ETCDCTL_API=3
```

## Authentication & TLS

In kubeadm-based clusters, etcd uses **mutual TLS**.

Required files:
- CA certificate
- Server certificate
- Server key

Location:

```bash
/etc/kubernetes/pki/etcd/
```

## Check etcd Endpoint Health

```bash
etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

## Check etcd Endpoint Status

```bash
etcdctl endpoint status \
  --endpoints=https://127.0.0.1:2379 \
  --write-out=table \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Shows:
- Leader
- DB size
- Raft term
- Revision

## Taking a Snapshot (Backup)

```bash
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Verify snapshot:

```bash
etcdctl snapshot status snapshot.db
```

## Restoring from Snapshot

```bash
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

After restore:
- Update etcd manifest
- Point to new data directory
- Restart etcd

🔗 Related:
- [[etcd]]
- [[Backup]]

## etcdctl Inside a Pod

If etcd runs as a static Pod:

```bash
kubectl exec -n kube-system etcd-controlplane -- sh
```

Then run etcdctl inside the container.

## Common Flags Reference

- --endpoints
- --cacert
- --cert
- --key
- --write-out=table

## Common Pitfalls

- Forgetting ETCDCTL_API=3
- Using wrong certificates
- Restoring over active data directory
- Directly editing keys

## Best Practices

- Use etcdctl only for admin tasks
- Automate backups
- Store snapshots off-node
- Never modify Kubernetes objects directly

## Key Mental Model

etcdctl is **brain surgery equipment**.

You don’t use it casually.
You don’t experiment with it.
When you use it, you move slowly, deliberately, and with backups ready.