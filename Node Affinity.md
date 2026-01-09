# Node Affinity
## Overview

**Node Affinity** lets you control **which Nodes Pods prefer or require**, based on **node labels**.
It is the **advanced successor** to [[Node Selectors]].

Node Affinity answers:
- _Where must this Pod run?_
- _Where would it like to run?_

## Affinity Types

Node Affinity has **two main behaviors**:
### Required (hard)

Pod **will not schedule** unless condition is met.

```yaml
requiredDuringSchedulingIgnoredDuringExecution
```

### Preferred (soft)

Scheduler **tries** to honor it but may ignore it.

```yaml
preferredDuringSchedulingIgnoredDuringExecution
```

## Required Node Affinity (Hard Rule)

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd
```

If no matching node exists → Pod stays Pending.

## Preferred Node Affinity (Soft Rule)

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: zone
          operator: In
          values:
          - eu-central
```

Scheduler scores nodes; higher weight = stronger preference.

## Operators

- In
- NotIn
- Exists
- DoesNotExist
- Gt
- Lt

Example:

```yaml
- key: cpu
  operator: Gt
  values:
  - "8"
```

## Multiple Terms Logic

- **OR** between nodeSelectorTerms
- **AND** within matchExpressions

Mental model:

```sql
(term1 OR term2) AND (expression1 AND expression2)
```

## IgnoredDuringExecution Explained

If node labels change **after scheduling**:
- Pod is **not evicted**
- Rule is only checked at scheduling time

This is almost always what you want.

## Node Affinity vs Taints & Tolerations

|**Feature**|**Node Affinity**|**Taints & Tolerations**|
|---|---|---|
|Controls attraction|Yes|No|
|Controls repulsion|No|Yes|
|Applied to|Pod|Node + Pod|
|Guarantees placement|Yes (required)|No|

Best practice:

> Use **taints** to block
> Use **affinity** to choose

## Common Use Cases

- Zone-aware scheduling
- SSD vs HDD
- GPU workloads
- Workload separation by hardware

## Debugging Affinity Issues

```bash
kubectl describe pod <pod-name>
```

Look for:

```bash
0/5 nodes are available: node(s) didn't match node affinity
```

## Key Mental Model

Node Affinity is:
- Declarative placement logic
- Scheduler-level intelligence
- A magnet, not a fence

Selectors lock doors.
Affinity nudges traffic.