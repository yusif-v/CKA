# etcdutl
## Overview

**etcdutl** is a **low-level utility tool** for working with **etcd data files directly**.

Unlike etcdctl, which talks to a **running etcd cluster**, etcdutl operates **offline**, on etcd **data directories and snapshots**.

It is mainly used for **inspection, verification, and disaster recovery**.

## etcdutl vs etcdctl

|**Feature**|**etcdutl**|**etcdctl**|
|---|---|---|
|Requires running etcd|No|Yes|
|Works offline|Yes|No|
|Talks to etcd API|No|Yes|
|Snapshot operations|Yes|Yes|
|Low-level inspection|Yes|No|

🔗 Related:
- [[etcd]]
- [[etcdctl]]
- [[Backup]]

## Common Use Cases

- Inspecting snapshot metadata
- Verifying snapshot integrity
- Working with corrupted data directories
- Disaster recovery scenarios

## Check Snapshot Status

```bash
etcdutl snapshot status snapshot.db
```

Shows:
- Revision
- Total keys
- DB size

## Snapshot Integrity Check

```bash
etcdutl snapshot status snapshot.db --write-out=table
```

Useful to confirm snapshot validity before restore.

## Snapshot Restore (Offline)

```bash
etcdutl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

This creates a **new etcd data directory**.

## Data Directory Inspection

Inspect an etcd data directory without running etcd:

```bash
etcdutl data-dir status /var/lib/etcd
```

## When to Use etcdutl

- etcd **cannot start**
- etcd data directory is corrupted
- Snapshot verification before restore
- Forensic analysis

## What etcdutl Cannot Do

- Modify live etcd data
- Interact with Kubernetes objects
- Replace etcdctl for normal operations

## Best Practices

- Use etcdctl for **normal backups**
- Use etcdutl for **offline recovery**
- Never run etcdutl on active data directory
- Always restore to a **new directory**

## Key Mental Model

etcdctl is a **remote control**.
etcdutl is a **workbench**.

One talks to a living system.
The other works on its organs **when the system is offline**.

You only reach for etcdutl when things have already gone quiet.