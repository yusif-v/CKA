---
tags: [cka/architecture, configuration]
aliases: [ResourceQuota, Quota, Namespace Quota, compute quota]
---

# ResourceQuota

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Namespaces]], [[Resource Limits]], [[Pods]], [[Deployments]], [[LimitRange]], [[RBAC]]

## Overview

A **ResourceQuota** is a namespace-scoped policy that **caps the total resource consumption** of all objects within a namespace. Where [[Resource Limits]] control what a single container can use, ResourceQuota controls what an entire namespace can consume in aggregate. It prevents any one team or application from monopolising cluster resources.

---

## What ResourceQuota Can Limit

ResourceQuota can enforce limits across three categories:

### Compute Resources

```yaml
spec:
  hard:
    requests.cpu: "4"         # Total CPU requests across all Pods
    requests.memory: 8Gi      # Total memory requests across all Pods
    limits.cpu: "8"           # Total CPU limits across all Pods
    limits.memory: 16Gi       # Total memory limits across all Pods
```

> [!warning]
> Once a ResourceQuota exists in a namespace that sets `requests.cpu` or `requests.memory`, **every Pod must define resource requests** or it will be rejected. Use [[LimitRange]] to set defaults automatically.

### Object Count

```yaml
spec:
  hard:
    pods: "20"                # Max number of Pods
    services: "10"            # Max number of Services
    secrets: "20"             # Max number of Secrets
    configmaps: "20"          # Max number of ConfigMaps
    persistentvolumeclaims: "5"
    services.nodeports: "2"
    services.loadbalancers: "1"
```

### Storage Resources

```yaml
spec:
  hard:
    requests.storage: 50Gi              # Total storage requested across all PVCs
    persistentvolumeclaims: "10"        # Max number of PVCs
    <storageclass>.storageclass.storage.k8s.io/requests.storage: 20Gi
```

---

## Full ResourceQuota Example

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: dev
spec:
  hard:
    # Compute
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    # Objects
    pods: "20"
    services: "10"
    secrets: "10"
    configmaps: "10"
    persistentvolumeclaims: "5"
    # Storage
    requests.storage: 20Gi
```

---

## Scopes

ResourceQuota can be scoped to apply only to certain types of Pods:

```yaml
spec:
  hard:
    pods: "10"
  scopes:
  - BestEffort       # Only applies to BestEffort QoS pods
  # Other scopes: NotBestEffort, Terminating, NotTerminating, PriorityClass
```

| Scope | Applies to |
|---|---|
| `BestEffort` | Pods with no requests or limits |
| `NotBestEffort` | Pods with any requests or limits |
| `Terminating` | Pods with `activeDeadlineSeconds` set |
| `NotTerminating` | Pods without `activeDeadlineSeconds` |
| `PriorityClass` | Pods of a specific priority class |

---

## ResourceQuota vs LimitRange

| Feature | ResourceQuota | LimitRange |
|---|---|---|
| Scope | Namespace total | Per Pod / Container |
| Enforces | Aggregate consumption | Individual resource bounds |
| Sets defaults | ❌ No | ✅ Yes |
| Blocks creation when exceeded | ✅ Yes | ✅ Yes |
| Use together? | ✅ Yes — complementary | ✅ Yes |

> [!tip] Exam Tip
> Use **LimitRange** to set default requests/limits so Pods aren't rejected by ResourceQuota. Use **ResourceQuota** to cap total namespace consumption. They are designed to work together.

---

## Key Commands

```bash
# List ResourceQuotas in a namespace
kubectl get resourcequota -n dev
kubectl get quota -n dev              # Short alias

# Describe quota — shows used vs hard limits
kubectl describe resourcequota team-quota -n dev

# Check quota usage across all namespaces
kubectl get resourcequota -A

# Create ResourceQuota imperatively (basic)
kubectl create quota team-quota \
  --hard=pods=20,requests.cpu=4,limits.cpu=8 \
  -n dev

# Dry run
kubectl create quota team-quota \
  --hard=pods=20,requests.cpu=4,limits.memory=8Gi \
  -n dev --dry-run=client -o yaml
```

### Reading `kubectl describe resourcequota` output

```
Name:            team-quota
Namespace:       dev
Resource         Used   Hard
--------         ----   ----
limits.cpu       1500m  8
limits.memory    2Gi    16Gi
pods             3      20
requests.cpu     500m   4
requests.memory  1Gi    8Gi
```

The `Used` column shows current consumption. When `Used` reaches `Hard`, new objects are rejected.

---

## Common Issues / Troubleshooting

- **Pod rejected with `exceeded quota`** → namespace has hit a hard limit; `kubectl describe resourcequota -n <ns>` to see which resource is exhausted
- **Pod rejected with `must specify requests`** → ResourceQuota enforces compute resources but Pod has no requests; add requests to Pod spec or apply a [[LimitRange]] with defaults
- **ResourceQuota not enforcing** → quota must be in the **same namespace** as the objects it limits; check with `kubectl get resourcequota -n <ns>`
- **Quota shows 0 used but pods exist** → quota was created after the pods; existing objects are counted on next update — describe the quota to verify
- **Can't delete namespace** → ResourceQuota may have finalizers; check `kubectl describe ns <ns>`

---

## Related Notes

- [[Namespaces]] — ResourceQuota is namespace-scoped; one or more quotas per namespace
- [[Resource Limits]] — Per-container limits; ResourceQuota enforces namespace totals
- [[LimitRange]] — Sets per-Pod/container defaults and bounds; complements ResourceQuota
- [[Pods]] — Pod creation blocked when quota is exceeded
- [[Deployments]] — New replica Pods blocked if namespace quota is full
- [[Scheduling]] — Quota enforcement happens at admission, before scheduling

## Key Mental Model

ResourceQuota is the **namespace budget**. LimitRange is the **spending policy per person**. The budget says the whole team can spend €1000 this month. The policy says each person must spend at least €10 and no more than €200. Without both, either one person blows the budget or the budget goes untracked.
