---
tags: [cka/workloads, workloads]
aliases: [Label, Annotations, Label Selector]
---

# Labels

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Scheduling]], [[Services]], [[Deployments]], [[Node Affinity]], [[kubectl]]

## Overview

**Labels** are key-value pairs attached to Kubernetes objects used for **identification, grouping, and selection**. They are not descriptions — they are **machine-readable indexes**. If labels are wrong, things silently stop working.

## Label Structure

```yaml
metadata:
  labels:
    app: frontend
    env: prod
    tier: web
    version: "1.25"
```

Rules:
- Keys are case-sensitive
- Values must be strings
- Keys can include a prefix: `team.example.com/role`
- Max key length: 63 chars (without prefix), 253 chars prefix

## Labels vs Annotations

| Feature | Labels | Annotations |
|---|---|---|
| Used for selection | ✅ Yes | ❌ No |
| Indexed by API | ✅ Yes | ❌ No |
| Size limit | Small | Large (arbitrary data) |
| Purpose | Identity / Selectors | Metadata / Reference |

Rule: **Labels = selectors. Annotations = explanations.**

## Selecting by Labels

### Equality-based

```bash
kubectl get pods -l app=frontend
kubectl get pods -l app!=frontend
kubectl get pods -l 'app=frontend,env=prod'   # AND condition
```

### Set-based

```bash
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l 'tier notin (db)'
kubectl get pods -l 'disktype'          # Exists
kubectl get pods -l '!disktype'         # DoesNotExist
```

## Labels in Resources

### Service Selector (critical — must match Pod labels)

```yaml
# Service
spec:
  selector:
    app: backend       # Matches pods with this label

# Pod must have:
metadata:
  labels:
    app: backend
```

### Deployment Selector (immutable after creation)

```yaml
spec:
  selector:
    matchLabels:
      app: web         # Cannot change after creation
  template:
    metadata:
      labels:
        app: web       # Must match selector
```

## Node Labels

Used with [[Node Affinity]] and `nodeSelector`:

```bash
# Add label to node
kubectl label node worker-1 disktype=ssd

# Remove label from node
kubectl label node worker-1 disktype-

# List nodes with their labels
kubectl get nodes --show-labels
```

## Key Commands

```bash
# Add label to resource
kubectl label pod nginx env=dev
kubectl label deployment web tier=frontend

# Overwrite existing label
kubectl label pod nginx env=prod --overwrite

# Remove label (trailing dash)
kubectl label pod nginx env-

# Filter resources by label
kubectl get pods -l app=web
kubectl get pods -l 'env in (prod,staging)'

# Show labels column
kubectl get pods --show-labels
```

## Common Issues / Troubleshooting

- **Service has no endpoints** → selector mismatch; `kubectl get endpoints <svc>` → `kubectl describe svc`
- **Deployment not controlling pods** → selector doesn't match pod template labels
- **Pods not receiving traffic** → pod label was edited but service selector not updated
- **nodeSelector not working** → node missing the label; `kubectl get nodes --show-labels`

## Related Notes

- [[Services]] — Use label selectors to find backend Pods
- [[Deployments]] — Selector must match pod template labels
- [[Scheduling]] — nodeSelector uses node labels
- [[Node Affinity]] — Advanced label-based node selection
- [[Network Policy]] — Uses pod/namespace label selectors

## Key Mental Model

Labels are not names or metadata blobs — they are **indexes**. If Kubernetes were a database, labels would be the **WHERE clause**. Everything that routes, selects, or schedules uses labels under the hood.
