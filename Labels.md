# Labels
## Overview

**Labels** are **key–value pairs** attached to Kubernetes objects.
They are used for **identification, grouping, and selection**, not for storing metadata descriptions.

Labels answer:

> _“Which resources belong together?”_

## Label Structure

```yaml
labels:
  app: frontend
  env: prod
  tier: web
```

Rules:
- Keys are case-sensitive
- Values are strings
- Keys can be scoped: team.example.com/role
- Immutable in purpose, but **changeable in practice**

## Where Labels Are Used

- [[Services]] selectors
- [[ReplicaSet Controller]] Pod matching
- [[Deployment Controller]] rollout logic
- [[NetworkPolicy]] targeting
- [[Scheduling]] (via node labels)
- [[kubectl]] filtering

If labels are wrong, **things silently stop working**.

## Selecting by Labels
### Equality-based selection

```bash
kubectl get pods -l app=frontend
```

```bash
kubectl get pods -l app!=frontend
```

### Set-based selection

```bash
kubectl get pods -l 'env in (prod,staging)'
```

```bash
kubectl get pods -l 'tier notin (db)'
```

## Adding & Modifying Labels
### Add label

```bash
kubectl label pod nginx env=dev
```

### Overwrite label

```bash
kubectl label pod nginx env=prod --overwrite
```

### Remove label

```bash
kubectl label pod nginx env-
```

## Labels vs Annotations

| **Feature**        | **Labels** | **Annotations** |
| ------------------ | ---------- | --------------- |
| Used for selection | Yes        | No              |
| Indexed            | Yes        | No              |
| Size limit         | Small      | Large           |
| Purpose            | Identity   | Metadata        |

Rule:
- **Labels = selectors**
- **Annotations = explanations**

## Labels in Workloads
### Pod template labels

```yaml
spec:
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
```

Selector **must match** Pod template labels, or controller breaks.

## Node Labels

Used in scheduling.

```bash
kubectl label node worker-1 disktype=ssd
```

```yaml
nodeSelector:
  disktype: ssd
```

## Common Label Mistakes

- Selector mismatch between Service and Pods
- Editing Pod labels but forgetting Service
- Using annotations where labels are required
- Overloading labels with descriptive text

## Key Mental Model

Labels are:
- Not names
- Not metadata blobs
- **Indexes**

If Kubernetes were a database, labels would be the **WHERE clause**.