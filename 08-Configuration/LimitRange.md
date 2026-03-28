---
tags: [cka/architecture, configuration]
aliases: [LimitRange, limit range, default limits, container defaults]
---

# LimitRange

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Namespaces]], [[Resource Limits]], [[ResourceQuota]], [[Pods]], [[Deployments]]

## Overview

A **LimitRange** is a namespace-scoped policy that enforces **minimum, maximum, and default resource constraints** on individual Pods and containers. While [[ResourceQuota]] caps the total consumption of a namespace, LimitRange controls what each individual container is allowed to request and use. It also solves the common problem of Pods being rejected by [[ResourceQuota]] because they have no resource requests defined — by injecting defaults automatically at admission.

---

## What LimitRange Controls

LimitRange can set constraints on three object types:

| Type | What it applies to |
|---|---|
| `Container` | Individual containers inside a Pod |
| `Pod` | Total resources across all containers in a Pod |
| `PersistentVolumeClaim` | Storage size for PVCs |

For each type it can define:

| Field | Meaning |
|---|---|
| `default` | Default **limit** injected if container specifies none |
| `defaultRequest` | Default **request** injected if container specifies none |
| `max` | Maximum allowed limit — container cannot exceed this |
| `min` | Minimum allowed request — container cannot go below this |
| `maxLimitRequestRatio` | Maximum ratio of limit to request (burst factor) |

---

## LimitRange Definition

### Container Defaults (most common exam pattern)

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: container-defaults
  namespace: dev
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
```

### Pod-level Limits

```yaml
spec:
  limits:
  - type: Pod
    max:
      cpu: "4"
      memory: "4Gi"
```

### PersistentVolumeClaim Size Limits

```yaml
spec:
  limits:
  - type: PersistentVolumeClaim
    max:
      storage: 10Gi
    min:
      storage: 1Gi
```

### Combined Example

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: team-limits
  namespace: dev
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
    min:
      cpu: "50m"
      memory: "64Mi"
  - type: PersistentVolumeClaim
    max:
      storage: 10Gi
    min:
      storage: 500Mi
```

---

## How Default Injection Works

When a container is created **without** resource requests or limits in a namespace that has a LimitRange:

```
Container spec has no resources defined
        ↓
Admission controller checks LimitRange
        ↓
Injects defaultRequest → becomes container's requests
Injects default       → becomes container's limits
        ↓
Pod is admitted with injected values
```

> [!tip] Exam Tip
> This is why LimitRange and [[ResourceQuota]] are used together. ResourceQuota rejects Pods with no requests. LimitRange automatically injects those requests so Pods are never rejected for missing them.

---

## Enforcement Rules

If a container **does** specify resources, LimitRange validates them:

- `requests` must be ≥ `min`
- `limits` must be ≤ `max`
- `limits / requests` must be ≤ `maxLimitRequestRatio`
- `requests` must be ≤ `limits`

If any rule is violated, the Pod is **rejected at admission** with a clear error message.

---

## LimitRange vs ResourceQuota

| Feature | LimitRange | ResourceQuota |
|---|---|---|
| Scope | Per Pod / Container | Namespace total |
| Sets defaults | ✅ Yes | ❌ No |
| Enforces min/max per object | ✅ Yes | ❌ No |
| Caps aggregate usage | ❌ No | ✅ Yes |
| Blocks creation when exceeded | ✅ Yes | ✅ Yes |
| Use together? | ✅ Yes — complementary | ✅ Yes |

---

## Key Commands

```bash
# List LimitRanges in a namespace
kubectl get limitrange -n dev
kubectl get limits -n dev              # Short alias

# Describe LimitRange — shows all configured bounds
kubectl describe limitrange container-defaults -n dev

# Check across all namespaces
kubectl get limitrange -A

# Create from file
kubectl apply -f limitrange.yaml

# Dry run
kubectl apply -f limitrange.yaml --dry-run=client
```

### Reading `kubectl describe limitrange` output

```
Name:       container-defaults
Namespace:  dev
Type        Resource  Min   Max  Default Request  Default Limit  Max Limit/Request Ratio
----        --------  ---   ---  ---------------  -------------  -----------------------
Container   cpu       50m   2    100m             500m           -
Container   memory    64Mi  2Gi  128Mi            256Mi          -
```

---

## Common Issues / Troubleshooting

- **Pod rejected with `exceeds max limit`** → container's limit is above the LimitRange `max`; reduce the limit in the Pod spec
- **Pod rejected with `below min`** → container's request is below the LimitRange `min`; increase it
- **Pod admitted but has unexpected resource values** → LimitRange injected defaults; check with `kubectl describe pod <pod>` → Resources section
- **LimitRange not injecting defaults** → LimitRange must exist in the namespace **before** the Pod is created; it does not retroactively update existing Pods
- **ResourceQuota still rejecting Pods despite LimitRange** → LimitRange defaults are injected but the namespace quota is already exhausted; check `kubectl describe resourcequota -n <ns>`
- **Wrong namespace** → LimitRange is namespace-scoped; verify with `kubectl get limitrange -n <ns>`

---

## Related Notes

- [[ResourceQuota]] — Caps namespace-total consumption; works alongside LimitRange
- [[Resource Limits]] — Per-container requests and limits; what LimitRange validates and defaults
- [[Namespaces]] — LimitRange is namespace-scoped; applies to all Pods in the namespace
- [[Pods]] — Pod creation validated and mutated by LimitRange at admission
- [[Deployments]] — All replica Pods subject to LimitRange rules in their namespace

## Key Mental Model

LimitRange is the **house rules** posted on the wall of each namespace. Before any container moves in, the rules are checked: you must request at least this much, you cannot take more than that, and if you don't say how much you need, here are the defaults. [[ResourceQuota]] is the total building capacity. LimitRange is what each tenant is individually allowed to use.
