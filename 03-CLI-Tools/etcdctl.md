---
tags: [cka/architecture, cli]
aliases: [etcd client, etcdctl backup]
---

# etcdctl

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[etcd]], [[etcdutl]], [[Backup]], [[TLS in Kubernetes]]

## Overview

**etcdctl** is the command-line client for interacting with a **running** [[etcd]] cluster. In Kubernetes, it is primarily used for health checks, snapshots (backup), and restore operations. Direct data manipulation is strongly discouraged.

> [!tip] Exam Tip
> Always set `ETCDCTL_API=3` and always provide the 3 TLS flags. The exam will have you run a backup/restore — know this command pattern by heart.

## API Version

Kubernetes uses **etcd API v3**. Always set:

```bash
export ETCDCTL_API=3
```

## TLS Authentication

In kubeadm clusters, etcd uses mutual TLS. Required flags for every command:

```bash
--cacert=/etc/kubernetes/pki/etcd/ca.crt
--cert=/etc/kubernetes/pki/etcd/server.crt
--key=/etc/kubernetes/pki/etcd/server.key
--endpoints=https://127.0.0.1:2379
```

## Key Commands

### Health Check

```bash
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### Endpoint Status (shows leader, DB size, revision)

```bash
ETCDCTL_API=3 etcdctl endpoint status \
  --endpoints=https://127.0.0.1:2379 \
  --write-out=table \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

### Take a Snapshot (Backup)

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db
```

### Restore from Snapshot

```bash
# Step 1: Restore to new directory
ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-restored

# Step 2: Update etcd static pod manifest
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd-restored
# Update: hostPath volume to /var/lib/etcd-restored

# Step 3: Static pod will restart automatically
# Verify: kubectl get pods -n kube-system
```

### Member Management (HA clusters)

```bash
# List members
etcdctl member list --endpoints=... --cacert=... --cert=... --key=...
```

## etcdctl Inside a Static Pod

If etcd runs as a static Pod, exec into it:

```bash
kubectl exec -n kube-system etcd-<node> -- sh -c \
  "ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key"
```

## Common Issues / Troubleshooting

- **"transport: Error"** → wrong certificate paths; double-check `--cacert`, `--cert`, `--key`
- **"connection refused"** → etcd not running or wrong endpoint
- **Forgot `ETCDCTL_API=3`** → commands fail or use wrong API
- **Restore to wrong data-dir** → etcd uses old data; update the manifest

## Related Notes

- [[etcd]] — The service etcdctl controls
- [[etcdutl]] — Offline tool for snapshot inspection (no live etcd needed)
- [[Backup]] — Full backup strategy and restore procedure
- [[TLS in Kubernetes]] — Certificate chain used for etcdctl auth

## Key Mental Model

etcdctl is **brain surgery equipment**. You don't use it casually. You don't experiment with it. When you use it, you move slowly, deliberately, and with backups ready.
