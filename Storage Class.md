# Storage Class
## Overview

A **StorageClass** defines how dynamic storage is provisioned in Kubernetes.

It acts as a template that tells Kubernetes:
- Which storage provider to use
- What type of disk to create
- Performance and policy settings for that storage

Instead of manually creating Persistent Volumes, Kubernetes can automatically create them when a user requests storage through a PersistentVolumeClaim (PVC).

StorageClass = _How storage should be created_
PVC = _Request for storage_

## Why StorageClass Exists

Before StorageClasses, administrators had to:
1. Manually create PersistentVolumes.
2. Match them to user claims.

This was static and painful.

StorageClass enables **Dynamic Provisioning**, meaning storage is created automatically when requested.

## How StorageClass Works

Workflow:

```bash
User creates PVC → Kubernetes checks StorageClass → 
Provisioner creates real storage → PV is created and bound → Pod uses it
```

The StorageClass tells Kubernetes which backend system should create the disk.

Examples of backends:
- Cloud disks (AWS EBS, Azure Disk, GCE PD)
- NFS
- Ceph
- Local storage
- CSI drivers

## Example StorageClass

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
```

This defines:
- Use AWS EBS
- Create gp3 SSD disks
- Delete disk when PVC is deleted
- Wait until a Pod is scheduled before provisioning

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

Kubernetes automatically creates the PersistentVolume using that StorageClass.

No manual PV required.

## Key StorageClass Fields

|**Field**|**Purpose**|
|---|---|
|provisioner|Plugin that creates the storage|
|parameters|Storage-specific configuration|
|reclaimPolicy|What happens when PVC is deleted|
|volumeBindingMode|When volume gets created|
|allowVolumeExpansion|Allows resizing volumes|

## Volume Binding Modes

**Immediate**
- Volume is created instantly after PVC is created.

**WaitForFirstConsumer**
- Volume is created only after Pod scheduling.
- Prevents wrong-zone provisioning in multi-zone clusters.

This is important for topology-aware storage.

## Reclaim Policies

|**Policy**|**Behavior**|
|---|---|
|Delete|Removes the actual disk when PVC is deleted|
|Retain|Keeps disk for manual recovery|
|Recycle|(Deprecated) Basic cleanup|

## Default StorageClass

Clusters can have a default StorageClass.

If a PVC does not specify one, Kubernetes uses the default automatically.

Check default:

```bash
kubectl get storageclass
```

Default class is marked with (default).

## Useful Commands

```bash
kubectl get storageclass
kubectl describe storageclass <name>

kubectl get pvc
kubectl get pv

kubectl delete pvc <name>
```

## Static vs Dynamic Provisioning

|**Type**|**Behavior**|
|---|---|
|Static|Admin creates PV manually|
|Dynamic|StorageClass provisions automatically|

Modern Kubernetes environments use dynamic provisioning almost exclusively.

## Important Behavior

StorageClass does not create storage by itself.
It only defines _how_ storage should be created when a PVC asks for it.

PVC triggers the action.
StorageClass defines the rules.
Provisioner performs the work.

## Summary

A StorageClass enables dynamic, automated storage provisioning by defining the backend, performance, and lifecycle behavior of volumes, allowing Kubernetes to create and manage storage on demand instead of relying on manually created PersistentVolumes.