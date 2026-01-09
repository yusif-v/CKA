#cli #architecture
## Overview

etcd is a highly available, distributed key-value store that serves as the backend database for Kubernetes. It stores all cluster data, including configuration, state, and metadata for resources like Pods, Services, Deployments, and ConfigMaps. etcd ensures strong consistency using the Raft consensus algorithm, which handles leader elections, data replication, and fault tolerance during network partitions or node failures. It operates as a clustered system, typically with 3, 5, or 7 nodes to maintain an odd-numbered quorum for majority-based decisions.

## Features
### Consistency and Reliability

- **Raft Consensus**: etcd uses Raft to achieve distributed consensus. A leader is elected to handle writes, while followers replicate data. It tolerates up to (N-1)/2 failures in a cluster of N nodes (e.g., 1 failure in 3 nodes).
- **Atomic Operations**: Supports Compare-And-Swap (CAS) for optimistic concurrency control, ensuring operations are atomic.
- **High Availability**: Data is replicated synchronously across nodes; automatic failover if the leader fails.

### Hierarchical Storage

- Data is organized in a directory-like structure (e.g., /registry/pods/default/my-pod), allowing prefix-based queries and range scans.
- Keys are strings, values are binary blobs (up to 1MB per key by default).

### Watches and Notifications

- Clients can watch specific keys, prefixes, or directories for changes (create, update, delete).
- Uses long-polling or streaming gRPC to notify clients in real-time, enabling reactive systems like the Kubernetes controller-manager.

### API Access

- **gRPC Protocol**: Primary interface over ports 2379 (client) and 2380 (peer).
- **etcdctl CLI**: Tool for interacting with etcd (e.g., `etcdctl get /key`, `etcdctl put /key value`).
- **Versions**: Defaults to v3 API; v2 is deprecated. Supports leases for TTL-based key expiration.

### Security Features

- **TLS Encryption**: All communications secured with mutual TLS; requires CA, server, and client certificates.
- **Authentication**: Supports client cert auth; role-based access control (RBAC) for users and roles.
- **Authorization**: Fine-grained permissions on keys and ranges.

## Kubernetes Integration
### Role in Cluster

- **Backing Store**: Kubernetes API server persists all objects to etcd (except runtime data like logs or images, stored elsewhere).
- **Watch Mechanism**: Components like scheduler and controllers watch etcd for events to reconcile desired vs. actual state.
- **Data Model**: Kubernetes resources stored under /registry prefix (e.g., /registry/pods/namespace/name).

### Deployment Options

- **Stacked Topology**: etcd runs on the same nodes as the control plane (default in kubeadm setups).
- **External Topology**: Separate etcd cluster for better isolation and scalability in large environments.
- **Sizing**: 3-5 nodes recommended; each needs SSD storage for low-latency I/O; monitor WAL (Write-Ahead Log) size.

### Configuration
- Config file: /etc/etcd/etcd.conf (YAML or flags).
- Key flags: --listen-client-urls, --advertise-client-urls, --initial-cluster.
- In Kubernetes manifests: Defined in /etc/kubernetes/manifests/etcd.yaml as a static Pod.

## Management
### Backup and Restore

- **Snapshot Backup**: `etcdctl snapshot save --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key /backup.db`
- **Restore**: Stop etcd, `etcdctl snapshot restore /backup.db --data-dir=/var/lib/etcd-from-backup`, then update cluster config and restart.
- **Best Practices**: Schedule regular backups (e.g., via cron); store off-cluster; test restores periodically.

### Operations with etcdctl

- **Basic Commands**: get (read), put (write), del (delete), txn (transactions), watch, lease grant/revoke/keepalive.
- **Cluster Management**: member list/add/remove/update, endpoint status/health.
- **Defragmentation**: `etcdctl defrag` to reclaim space from deleted keys.

### Monitoring and Metrics

- **Health Checks**: `etcdctl endpoint health --endpoints=https://etcd.example.com:2379`
- **Metrics**: Exposed via /metrics endpoint (Prometheus format); key metrics: etcd_server_leader_changes_seen_total, etcd_mvcc_db_total_size_in_bytes.
- **Logs**: Stored in /var/log/etcd.log or journald; check for errors like "request timed out" or "no leader".

### Troubleshooting

- **Common Issues**: Quorum loss (e.g., even number of nodes), high latency (slow disks), certificate expiry, network splits.
- **Diagnosis**: Use `etcdctl alarm list/disarm` for alarms; check raft status with `etcdctl endpoint status`.
- **Recovery**: For single-node failure, add new member; for total loss, restore from snapshot.

## Scaling and Performance

- **Horizontal Scaling**: Add/remove members dynamically; ensure odd quorum.
- **Tuning**: Adjust --max-request-bytes, --quota-backend-bytes for large clusters.
- **Performance Tips**: Use SSDs, isolate from noisy neighbors, monitor IOPS.

## etcdctl Utility

etcdctl is the command-line interface (CLI) tool for interacting with etcd servers. It allows administrators to perform operations like reading, writing, watching, and managing cluster data. etcdctl supports authentication and secure connections, making it essential for production environments.

### API Versions

etcdctl supports two API versions for etcd interactions: Version 2 (deprecated) and Version 3 (recommended and default in newer releases). The default API version is 2 unless explicitly set. Switching versions changes the available commands, and commands from one version are incompatible with the other.

#### Setting API Version

- Use the environment variable `ETCDCTL_API` to specify the version.
- Command: `export ETCDCTL_API=3` (to use Version 3).
- If not set, defaults to Version 2; Version 3 commands will fail.
- After setting to 3, Version 2 commands will not work.

### Version 2 Commands

Version 2 uses a simpler, flat key-value model. Key commands include:
- `etcdctl backup`: Creates a backup of the etcd data.
- `etcdctl cluster-health`: Checks the health status of the etcd cluster.
- `etcdctl mk <key> <value>`: Creates a new key with the given value (fails if key exists).
- `etcdctl mkdir <dir>`: Creates a new directory.
- `etcdctl set <key> <value>`: Sets or updates a key's value (overwrites if exists).
- Other common ones: `get`, `rm`, `rmdir`, `ls`, `update`.

### Version 3 Commands

Version 3 introduces features like transactions, leases, and watches with a more efficient API. Key commands include:
- `etcdctl snapshot save <path>`: Saves a snapshot of the etcd database to a file.
- `etcdctl endpoint health`: Verifies the health of etcd endpoints.
- `etcdctl get <key>`: Retrieves the value of a key (supports options like --prefix for ranges).
- `etcdctl put <key> <value>`: Inserts or updates a key-value pair.
- Other essential ones: `del` (delete), `txn` (transactions), `watch` (monitor changes), `lease` (manage leases for TTL), `member` (cluster membership operations like list/add/remove), `defrag` (reclaim space), `alarm` (handle alarms for issues like no space).

### Authentication and Security

etcdctl requires certificate-based authentication for secure clusters (common in Kubernetes):
- `--cacert <path>`: Path to the CA certificate (e.g., /etc/kubernetes/pki/etcd/ca.crt).
- `--cert <path>`: Path to the client certificate (e.g., /etc/kubernetes/pki/etcd/server.crt).
- `--key <path>`: Path to the client key (e.g., /etc/kubernetes/pki/etcd/server.key).
- These flags ensure TLS encryption and mutual authentication when connecting to etcd.

### Usage in Kubernetes

In a Kubernetes environment, etcd often runs as a Pod (e.g., etcd-master in kube-system namespace). Use `kubectl exec` to run etcdctl commands inside the Pod:
- Example (listing keys with limits):
```bash
kubectl exec etcd-master -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl get / --prefix --keys-only --limit=10 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key"
```
- This combines API version setting, command execution, and certificate authentication in one invocation.

### Advanced Options

- **Endpoints**: Specify etcd servers with `--endpoints=<url1>,<url2>` (e.g., https://127.0.0.1:2379).
- **Dial Timeout**: Use `--dial-timeout=<duration>` for connection timeouts.
- **Write-Out**: `--write-out=<format>` (e.g., json) for structured output.
- **Debugging**: Add `--debug` for verbose logging.

### Best Practices

- Always use Version 3 for new setups due to better performance and features.
- Script commands with environment variables for automation.
- Test commands in non-production environments to avoid data loss.
- Combine with monitoring tools for proactive management.
