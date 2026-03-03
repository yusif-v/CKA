---
tags: [cka/storage, storage]
aliases: [PV, PersistentVolume, Cluster Storage]
---

# Persistent Volumes

> **Exam Domain**: Storage (10%)
> **Related**: [[Persistent Volume Claims]], [[Storage Class]], [[Pods]], [[Backup]]

## Overview

A **Persistent Volume (PV)** is a cluster-level storage resource that has been provisioned — either by an administrator (static) or automatically by a [[Storage Class]] (dynamic). PVs are **independent of any [[Pods|Pod]]** and persist beyond the Pod's lifecycle.

PVs represent the **actual storage** (disk, NFS mount, cloud volume). [[Persistent Volume Claims|PVCs]] are the **requests** to use that storage.

## PV Lifecycle

```
Provisioning → Available → Bound → Released → Recycled/Retained/Deleted
```

| Phase | Meaning |
|---|---|
| `Available` | PV exists and is free to be claimed |
| `Bound` | PV is bound to a PVC |
| `Released` | PVC was deleted; PV not yet reclaimed |
| `Failed` | Automatic reclamation failed |

## Static PV Definition

Admin creates the PV manually before a PVC can claim it:

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-nfs
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteMany       # Multiple pods can read/write
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""  # Empty = no StorageClass (static)
  nfs:
    path: /mnt/data
    server: nfs-server.example.com
```

## Access Modes

| Mode | Abbreviation | Meaning |
|---|---|---|
| `ReadWriteOnce` | RWO | Single node read/write |
| `ReadOnlyMany` | ROX | Multiple nodes read-only |
| `ReadWriteMany` | RWX | Multiple nodes read/write |
| `ReadWriteOncePod` | RWOP | Single Pod read/write (k8s 1.22+) |

> [!note] Access mode support depends on the storage backend. Not all backends support RWX.

## Reclaim Policies

| Policy | Behavior After PVC Deletion |
|---|---|
| `Retain` | PV kept; must be manually reclaimed |
| `Delete` | PV and backing storage deleted |
| `Recycle` | *(Deprecated)* Basic data scrub |

## Storage Backends

Examples of volume types in PV spec:

```yaml
# NFS
nfs:
  path: /data
  server: 192.168.1.100

# HostPath (single-node only, development)
hostPath:
  path: /mnt/data
  type: DirectoryOrCreate

# AWS EBS (use CSI driver in modern clusters)
awsElasticBlockStore:
  volumeID: vol-0123456789
  fsType: ext4

# CSI (modern standard)
csi:
  driver: ebs.csi.aws.com
  volumeHandle: vol-0123456789
  fsType: ext4
```

## PV and PVC Binding

A PV and PVC are bound when:
1. PV capacity ≥ PVC requested storage
2. Access modes match
3. `storageClassName` matches (or both empty)
4. Label selector matches (if specified)

Binding is **one-to-one** — a PV can only be bound to one PVC at a time.

## Dynamic PV Creation (via StorageClass)

When a PVC references a [[Storage Class]], the provisioner **automatically creates a PV**:

```yaml
# PVC triggers PV creation
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  storageClassName: fast-storage
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

## Key Commands

```bash
# List PVs
kubectl get pv

# Describe PV
kubectl describe pv pv-nfs

# Check binding status
kubectl get pv,pvc

# Check PV reclaim policy
kubectl get pv -o custom-columns=NAME:.metadata.name,RECLAIM:.spec.persistentVolumeReclaimPolicy

# Manually reclaim a Released PV (Retain policy)
# 1. Delete the PV
kubectl delete pv pv-nfs
# 2. Clean up data on storage backend
# 3. Re-create the PV
```

## Common Issues / Troubleshooting

- **PVC stuck Pending** → No matching PV (capacity, accessMode, or storageClass mismatch); `kubectl describe pvc`
- **PV stuck Released** → `Retain` policy; old binding remains in PV spec; must manually clean `.spec.claimRef`
- **PV stuck Available but not binding** → storageClassName mismatch; check PV and PVC `storageClassName`
- **Storage full** → check PVC usage from inside Pod with `df -h`

## Related Notes

- [[Persistent Volume Claims]] — How Pods request PV storage
- [[Storage Class]] — Enables automatic PV provisioning
- [[Backup]] — PVs hold application data; back them up
- [[Pods]] — Pods access PVs through PVCs

## Key Mental Model

A PV is a **storage unit in a warehouse**. It exists independently, ready to be claimed. A PVC is the **requisition form** — it says "I need 5GB that I can read/write". Kubernetes matches form to unit based on size, access mode, and class. Once matched, they're locked together until the claim is released.
