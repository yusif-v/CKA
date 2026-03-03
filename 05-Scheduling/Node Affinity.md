---
tags: [cka/workloads, workloads]
aliases: [nodeAffinity, Pod Affinity, Affinity Rules]
---

# Node Affinity

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Scheduling]], [[Taints]], [[Labels]], [[kube-scheduler]], [[Pods]]

## Overview

**Node Affinity** is an advanced scheduling mechanism that allows fine-grained control over which Nodes a Pod can be scheduled on. It replaces and extends `nodeSelector` with support for complex expressions and soft (preferred) rules.

## Affinity Types

| Type | Effect |
|---|---|
| `requiredDuringSchedulingIgnoredDuringExecution` | Hard rule — Pod WILL NOT schedule if not met |
| `preferredDuringSchedulingIgnoredDuringExecution` | Soft rule — scheduler prefers but will schedule elsewhere |

> "IgnoredDuringExecution" means: if a Node's labels change after the Pod is running, the Pod is **not** evicted.

## Hard Affinity (Required)

Pod will only schedule on Nodes with `disktype=ssd` or `disktype=nvme`:

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd
            - nvme
```

## Soft Affinity (Preferred)

Scheduler prefers Nodes in `zone=eu-west`, but will schedule elsewhere if none available:

```yaml
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100    # Higher weight = stronger preference (1-100)
        preference:
          matchExpressions:
          - key: zone
            operator: In
            values:
            - eu-west
```

## Combining Required and Preferred

```yaml
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values: [linux]
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 50
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values: [ssd]
```

## Operators

| Operator | Meaning |
|---|---|
| `In` | Label value is in the list |
| `NotIn` | Label value is NOT in the list |
| `Exists` | Label key exists (any value) |
| `DoesNotExist` | Label key does not exist |
| `Gt` | Value greater than (numeric strings) |
| `Lt` | Value less than (numeric strings) |

## nodeSelector vs Node Affinity

| Feature | nodeSelector | Node Affinity |
|---|---|---|
| Expression support | Only equality | In, NotIn, Exists, etc. |
| Soft rules | ❌ | ✅ (preferred) |
| Multiple values | ❌ | ✅ |
| Syntax | Simple | Verbose but powerful |

## Pod Affinity / Anti-Affinity

Schedule Pods relative to **other Pods** (not just Nodes):

```yaml
# Co-locate with pods that have app=cache
affinity:
  podAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
    - labelSelector:
        matchLabels:
          app: cache
      topologyKey: kubernetes.io/hostname

# Keep away from pods with app=web
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchLabels:
            app: web
        topologyKey: kubernetes.io/hostname
```

## Key Commands

```bash
# List node labels
kubectl get nodes --show-labels

# Add label to node
kubectl label node worker-1 disktype=ssd

# Remove label from node
kubectl label node worker-1 disktype-

# Describe pod to see affinity scheduling decision
kubectl describe pod <pod-name>
```

## Common Issues / Troubleshooting

- **Pod stuck Pending with no nodes match affinity** → check node labels, operator and values; `kubectl get nodes --show-labels`
- **Soft affinity not respected** → expected behavior if no nodes match preference and scheduler places elsewhere
- **Multiple nodeSelectorTerms** → they are OR'd (any term can match)
- **Multiple matchExpressions in one term** → they are AND'd (all must match)

## Related Notes

- [[Scheduling]] — Where node affinity fits in the full picture
- [[Taints]] — Complementary mechanism (node pushes pods away)
- [[Labels]] — Node labels are what affinity rules evaluate
- [[kube-scheduler]] — Evaluates affinity during filtering and scoring

## Key Mental Model

Node Affinity is **attraction rules for Pods**. Required rules are deal-breakers; preferred rules are wishful thinking. Together they give you precise control over where workloads land — without hardcoding node names.
