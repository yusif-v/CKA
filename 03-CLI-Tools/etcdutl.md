---
tags: [cka/architecture, cli]
aliases: [etcdutl offline, etcd offline tool]
---

# etcdutl

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[etcd]], [[etcdctl]], [[Backup]]

## Overview

**etcdutl** is a **low-level utility** for working with [[etcd]] data files **directly** — without a running etcd cluster. Unlike [[etcdctl]], which communicates with a live etcd API, etcdutl operates **offline** on data directories and snapshot files. It is used for inspection, verification, and disaster recovery.

## etcdutl vs etcdctl

| Feature | etcdutl | etcdctl |
|---|---|---|
| Requires running etcd | ❌ No | ✅ Yes |
| Works offline | ✅ Yes | ❌ No |
| Talks to etcd API | ❌ No | ✅ Yes |
| Snapshot operations | ✅ Yes | ✅ Yes |
| Low-level inspection | ✅ Yes | ❌ No |

## Common Use Cases

- Inspecting snapshot metadata offline
- Verifying snapshot integrity before restore
- Working with corrupted data directories
- Disaster recovery when etcd cannot start

## Key Commands

### Check Snapshot Status

```bash
# Check snapshot integrity and metadata
etcdutl snapshot status snapshot.db

# Table format (more readable)
etcdutl snapshot status snapshot.db --write-out=table
```

Output shows:
- Hash (integrity check)
- Revision
- Total keys
- DB size

### Snapshot Restore (Offline)

```bash
# Restore snapshot to a new data directory
etcdutl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-restored
```

> [!note] Note
> Use [[etcdctl]] `snapshot restore` for normal restore operations. `etcdutl snapshot restore` is the newer equivalent but both create a new data directory.

### Data Directory Status

```bash
# Inspect etcd data directory without running etcd
etcdutl data-dir status /var/lib/etcd
```

## When to Use etcdutl

Use etcdutl when:
- etcd **cannot start** (corruption or config issues)
- You need to **verify a snapshot** before attempting restore
- Performing **forensic analysis** on etcd data
- [[etcdctl]] is not available (offline environment)

## When NOT to Use etcdutl

- Normal backup operations → use [[etcdctl]] `snapshot save`
- Interacting with live cluster → use [[etcdctl]]
- Creating/managing Kubernetes objects → use [[kubectl]]

## Common Issues / Troubleshooting

- **Never run etcdutl on an active data directory** → risk of corruption
- **Always restore to a NEW directory** → never overwrite live data
- **etcdutl not available** → may need to install separately from etcdctl

## Related Notes

- [[etcdctl]] — For live etcd operations (backup, health check)
- [[etcd]] — The service these tools manage
- [[Backup]] — Full backup and restore strategy

## Key Mental Model

etcdctl is a **remote control** — it talks to a living system.
etcdutl is a **workbench** — it works on the system's organs when it's offline.

You only reach for etcdutl when things have gone quiet.
