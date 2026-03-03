---
tags: [cka/storage, storage]
aliases: [PVC, PersistentVolumeClaim, Storage Request]
---

# Persistent Volume Claims

> **Exam Domain**: Storage (10%)
> **Related**: [[Persistent Volumes]], [[Storage Class]], [[Pods]], [[Namespaces]]

## Overview

A **Persistent Volume Claim (PVC)** is a **namespace-scoped request for storage** made by a user or application. It specifies how much storage is needed, what access mode is required, and optionally which [[Storage Class]] to use. Kubernetes then binds the PVC to a matching [[Persistent Volumes|PV]] — creating one dynamically if a StorageClass is specified.

PVCs are the **bridge between Pods and persistent storage**.

## PVC Lifecycle

```
Created → Pending → Bound → Used by Pod → Released (PVC deleted) → PV Reclaimed
```

| Phase | Meaning |
|---|---|
| `Pending` | Waiting for matching PV or dynamic provisioning |
| `Bound` | Successfully bound to a PV |
| `Lost` | Bound PV has disappeared |

## PVC Definition

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
  namespace: production
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-storage   # Omit to use default StorageClass
```

## Binding to a Specific Static PV

Using a label selector:

```yaml
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
  storageClassName: ""   # Empty = static binding only
  selector:
    matchLabels:
      type: nfs-storage
```

## Using PVCs in Pods

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
spec:
  volumes:
  - name: web-data
    persistentVolumeClaim:
      claimName: app-pvc     # Must exist in same namespace

  containers:
  - name: web
    image: nginx
    volumeMounts:
    - name: web-data
      mountPath: /usr/share/nginx/html
```

## Using PVCs in Deployments

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
spec:
  replicas: 1      # ReadWriteOnce PVCs can only be mounted by one Pod
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: app-pvc
      containers:
      - name: web
        image: nginx
        volumeMounts:
        - name: storage
          mountPath: /data
```

## PVC and Access Modes

A PVC's access mode must be **compatible** with the PV it binds to:

| PVC access mode | Compatible PV modes |
|---|---|
| `ReadWriteOnce` | RWO, RWX |
| `ReadOnlyMany` | ROX, RWX |
| `ReadWriteMany` | RWX only |

## Volume Expansion (Resizing PVCs)

If [[Storage Class]] has `allowVolumeExpansion: true`:

```bash
# Edit PVC to increase storage (decrease not supported)
kubectl patch pvc app-pvc -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'

# Or edit directly
kubectl edit pvc app-pvc
# Change: storage: 10Gi → 20Gi
```

## Key Commands

```bash
# List PVCs
kubectl get pvc
kubectl get pvc -n production

# Describe PVC (shows binding, capacity, events)
kubectl describe pvc app-pvc

# Check what PV a PVC is bound to
kubectl get pvc app-pvc -o jsonpath='{.spec.volumeName}'

# Check bound PV details
kubectl get pv $(kubectl get pvc app-pvc -o jsonpath='{.spec.volumeName}')

# Delete PVC (triggers PV reclaim policy)
kubectl delete pvc app-pvc
```

## Common Issues / Troubleshooting

- **PVC stuck Pending** → no matching PV or StorageClass not found; `kubectl describe pvc` shows reason
- **Capacity mismatch** → PVC requests more than any available PV; check `kubectl get pv`
- **storageClassName mismatch** → PVC `storageClassName: ""` won't match StorageClass PVs
- **Pod can't start** → PVC not yet Bound; Pod waits until PVC binds
- **Two Pods can't share RWO PVC** → ReadWriteOnce allows only one Node; use RWX or separate PVCs

## Related Notes

- [[Persistent Volumes]] — The actual storage resources PVCs bind to
- [[Storage Class]] — Enables dynamic PV provisioning triggered by PVCs
- [[Pods]] — Consume PVCs as volumes
- [[Namespaces]] — PVCs are namespace-scoped; PVs are cluster-scoped

## Key Mental Model

A PVC is a **lease agreement for storage**. The Pod says "I need 10GB to read/write". The PVC is the signed contract. Kubernetes finds matching available storage (PV) and locks them together. The storage persists even when the Pod leaves — until the lease (PVC) is terminated.
