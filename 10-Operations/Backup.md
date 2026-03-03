---
tags: [cka/architecture, operations]
aliases: [etcd backup, cluster backup, snapshot]
---

# Backup

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[etcd]], [[etcdctl]], [[etcdutl]], [[kube-apiserver]], [[Persistent Volumes]]

## Overview

**Backup** in Kubernetes means preserving **cluster state and application data** so it can be restored after failures, upgrades, or disasters. The most critical backup is [[etcd]] — it holds all cluster state. Without it, the cluster loses memory of everything it was managing.

> [!tip] Exam Tip
> etcd backup and restore commands are **heavily tested**. You will be asked to save and restore a snapshot. Know the full command with all TLS flags.

## What to Back Up

### Cluster State (Critical)

- **etcd data** — the most important backup
- Kubernetes manifests in `/etc/kubernetes/`
- PKI certificates in `/etc/kubernetes/pki/`

### Application Data

- [[Persistent Volumes]] containing application data
- External databases
- Object storage (S3, GCS)

## etcd Snapshot Backup

> [!tip] Exam Tip
> Memorize this command pattern — it will be on the exam.

```bash
ETCDCTL_API=3 etcdctl snapshot save /opt/etcd-backup.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify the snapshot
ETCDCTL_API=3 etcdctl snapshot status /opt/etcd-backup.db --write-out=table
```

## etcd Snapshot Restore (Full Procedure)

```bash
# Step 1: Restore snapshot to new data directory
ETCDCTL_API=3 etcdctl snapshot restore /opt/etcd-backup.db \
  --data-dir=/var/lib/etcd-from-backup

# Step 2: Update etcd static pod manifest
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change --data-dir to /var/lib/etcd-from-backup
# Update the hostPath volume:
#   volumes:
#   - hostPath:
#       path: /var/lib/etcd-from-backup  ← change this
#       type: DirectoryOrCreate
#     name: etcd-data

# Step 3: Wait for etcd to restart automatically
# Static pod will restart when manifest changes
kubectl get pods -n kube-system | grep etcd

# Step 4: Verify cluster is healthy
kubectl get nodes
kubectl get pods -A
```

## Backup Kubernetes Manifests and Certificates

```bash
# Backup critical config directories
tar -czvf k8s-config-backup.tar.gz \
  /etc/kubernetes/manifests \
  /etc/kubernetes/pki \
  /etc/kubernetes/*.conf

# Or individual components
cp -r /etc/kubernetes/pki /backup/pki
cp /etc/kubernetes/admin.conf /backup/
```

## Application-Level Backups

### Velero (Popular Tool)

```bash
# Backup entire cluster
velero backup create full-cluster-backup

# Backup specific namespace
velero backup create dev-backup --include-namespaces=dev

# Restore
velero restore create --from-backup full-cluster-backup

# Schedule automated backups
velero schedule create daily-backup \
  --schedule="0 1 * * *" \
  --include-namespaces=production
```

### Volume Snapshots

For [[Persistent Volumes]], use CSI volume snapshots or storage-native backup tools.

## Key Commands

```bash
# Take snapshot
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Verify snapshot integrity
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db

# Or use etcdutl (offline)
etcdutl snapshot status /opt/snapshot.db --write-out=table

# Restore
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot.db \
  --data-dir=/var/lib/etcd-from-backup
```

## Backup Strategy Best Practices

- Automate etcd backups (cron job)
- Store backups **off-cluster** (S3, NFS, remote)
- Encrypt backup data
- **Test restores regularly** — a backup you've never restored is untested
- Version-control YAML manifests in Git
- Back up both etcd AND application volumes

## Common Issues / Troubleshooting

- **Restore doesn't show new state** → forgot to update `--data-dir` in etcd manifest
- **etcd won't start after restore** → volume hostPath in manifest not updated; check both `--data-dir` flag AND volume mount
- **Snapshot verify fails** → snapshot corrupted; take a fresh backup
- **No TLS flags** → etcdctl commands fail without `--cacert --cert --key`
- **Wrong endpoints** → check etcd is on `https://127.0.0.1:2379` (verify in etcd pod spec)

## Related Notes

- [[etcd]] — What's being backed up
- [[etcdctl]] — Tool used for snapshot save and restore
- [[etcdutl]] — Offline tool for snapshot verification
- [[Static Pods]] — etcd manifest lives in `/etc/kubernetes/manifests/etcd.yaml`
- [[Persistent Volumes]] — Application data also needs backup

## Key Mental Model

Backups are **time machines for state**. Containers are disposable. Pods are temporary. **State is sacred.** If you can restore etcd and data volumes, Kubernetes can rebuild everything else. The cluster is just a machine — etcd is its memory.
