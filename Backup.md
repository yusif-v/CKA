# Backup
## Overview

A **Backup** in Kubernetes means preserving **cluster state and application data** so it can be restored after failures, upgrades, or disasters.

Kubernetes backups focus on **state**, not running containers.

Two main backup categories:
- **Cluster state backups** (etcd, manifests)
- **Application data backups** (volumes)

## What Needs to Be Backed Up
### Cluster State

- **etcd data**
- Kubernetes manifests (YAMLs)
- Certificates and kubeconfig files

🔗 Related:
- [[etcd]]
- [[kube-apiserver]]
- [[Manifests]]

### Application Data

- Persistent Volumes (PV)
- External databases
- Object storage

🔗 Related:
- [[Persistent Volumes]]
- [[Persistent Volume Claims]]

## etcd Backup
### Why etcd Matters

etcd stores:
- All cluster objects
- Configurations
- Secrets
- State of the cluster
    

  

If etcd is lost, the cluster **forgets everything**.

---

### **etcd Snapshot Backup**

```
ETCDCTL_API=3 etcdctl snapshot save snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

Verify snapshot:

```
ETCDCTL_API=3 etcdctl snapshot status snapshot.db
```

---

## **etcd Restore**

```
ETCDCTL_API=3 etcdctl snapshot restore snapshot.db \
  --data-dir=/var/lib/etcd-from-backup
```

Update etcd configuration to use restored data directory.

---

## **Backup Kubernetes Manifests**

  

Critical directories:

- /etc/kubernetes/manifests
    
- /etc/kubernetes/pki
    

```
tar -czvf k8s-config-backup.tar.gz /etc/kubernetes
```

---

## **Application-Level Backups**

  

Options:

- Storage-level snapshots
    
- Backup tools (Velero)
    
- Database-native backups
    

  

🔗 Related:

- [[ConfigMap]]
    
- [[Secrets]]
    

---

## **Velero (Common Tool)**

  

Velero backs up:

- Kubernetes objects
    
- Persistent volumes (with snapshot support)
    

  

High-level usage:

```
velero backup create full-cluster-backup
```

Restore:

```
velero restore create --from-backup full-cluster-backup
```

---

## **Backup Strategy Best Practices**

- Automate backups
    
- Store backups **off-cluster**
    
- Encrypt backup data
    
- Test restores regularly
    
- Version control YAML manifests
    

---

## **Common Pitfalls**

- Backing up only manifests, not etcd
    
- Not testing restore procedures
    
- Keeping backups on the same node
    
- Forgetting certificates
    

---

## **Key Mental Model**

  

Backups are **time machines for state**.

  

Containers are disposable.

Pods are temporary.

**State is sacred.**

  

If you can restore etcd and data volumes, Kubernetes can rebuild everything else.