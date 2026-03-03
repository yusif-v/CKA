---
tags: [cka/storage, storage]
aliases: [StorageClass, Dynamic Provisioning, Storage Provisioner]
---

# Storage Class

> **Exam Domain**: Storage (10%)
> **Related**: [[Persistent Volumes]], [[Persistent Volume Claims]], [[Pods]]

## Overview

A **StorageClass** defines **how dynamic storage should be provisioned** in Kubernetes. It acts as a template telling Kubernetes which storage backend to use, what type of disk to create, and what lifecycle policies apply. Instead of manually creating [[Persistent Volumes]], Kubernetes automatically creates them when a [[Persistent Volume Claims|PVC]] references a StorageClass.

## Why StorageClass Exists

Before StorageClass, admins had to:
1. Manually create PersistentVolumes
2. Match them to user claims

StorageClass enables **Dynamic Provisioning** — storage is created automatically on demand.

## How It Works

```
User creates PVC with storageClassName
  → Kubernetes checks StorageClass
  → Provisioner creates real storage
  → PV is created and bound to PVC
  → Pod mounts the PVC
```

## StorageClass Definition

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

## Key Fields

| Field | Description |
|---|---|
| `provisioner` | Plugin/driver that creates the storage |
| `parameters` | Storage-specific configuration (type, IOPS, etc.) |
| `reclaimPolicy` | What happens when PVC is deleted |
| `volumeBindingMode` | When volume gets provisioned |
| `allowVolumeExpansion` | Whether PVC can be resized |

## Reclaim Policies

| Policy | Behavior |
|---|---|
| `Delete` | Actual storage deleted when PVC is deleted |
| `Retain` | Storage kept for manual recovery |
| `Recycle` | *(Deprecated)* Basic scrub |

## Volume Binding Modes

| Mode | When volume is created |
|---|---|
| `Immediate` | As soon as PVC is created |
| `WaitForFirstConsumer` | When a Pod using the PVC is scheduled (zone-aware) |

Use `WaitForFirstConsumer` in multi-zone clusters to avoid wrong-zone provisioning.

## Default StorageClass

If a PVC has no `storageClassName`, Kubernetes uses the cluster default:

```bash
# Check which is default
kubectl get storageclass
# Default shows (default) annotation

# Set a StorageClass as default
kubectl patch storageclass <name> -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

## Using StorageClass in a PVC

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-storage
```

## Key Commands

```bash
# List storage classes
kubectl get storageclass
kubectl get sc

# Describe storage class
kubectl describe storageclass fast-storage

# Check PVCs
kubectl get pvc

# Check PVs (created automatically by StorageClass)
kubectl get pv
```

## Static vs Dynamic Provisioning

| Type | How | When |
|---|---|---|
| Static | Admin creates PV manually | No StorageClass or specific PV |
| Dynamic | StorageClass provisions automatically | PVC references StorageClass |

## Common Issues / Troubleshooting

- **PVC stuck Pending** → StorageClass not found or provisioner not running
- **Wrong zone** → use `WaitForFirstConsumer` binding mode
- **PVC can't expand** → `allowVolumeExpansion: false`; recreate with new StorageClass
- **No default StorageClass** → PVC without `storageClassName` won't bind

## Related Notes

- [[Persistent Volumes]] — The actual storage resource created by StorageClass
- [[Persistent Volume Claims]] — What triggers dynamic provisioning
- [[Pods]] — Pods consume PVCs to access storage

## Key Mental Model

StorageClass is the **recipe card**, not the meal. The PVC is the **order**, and the provisioner is the **kitchen** that cooks from the recipe. StorageClass defines *how* storage is made; it doesn't make anything until a PVC asks for it.
