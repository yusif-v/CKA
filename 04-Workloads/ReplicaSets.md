---
tags: [cka/workloads, workloads]
aliases: [ReplicaSets, RS, replica controller]
---

# ReplicaSets

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[Deployments]], [[kube-controller-manager]], [[Labels]], [[Autoscaling]]

## Overview

A **ReplicaSet** ensures that a **specified number of Pod replicas** are running at all times. If a Pod dies, the ReplicaSet creates a replacement. If there are too many, it deletes the excess. ReplicaSets are the mechanism behind [[Deployments]] — in practice, you rarely create them directly.

> [!tip] Exam Tip
> You almost never create a ReplicaSet directly on the exam. Use [[Deployments]] instead — they wrap ReplicaSets and add rolling updates and rollbacks. Know ReplicaSets to understand how Deployments work internally.

## ReplicaSet vs Deployment

| Feature | ReplicaSet | Deployment |
|---|---|---|
| Maintains Pod count | ✅ | ✅ |
| Rolling updates | ❌ | ✅ |
| Rollback | ❌ | ✅ |
| Manages ReplicaSets | ❌ | ✅ (creates and swaps RS) |
| Direct use in production | Rarely | ✅ Standard |

## How ReplicaSets Work

```
1. You define desired replica count + Pod template + selector
2. ReplicaSet Controller (in kube-controller-manager) watches Pod count
3. Actual < Desired → creates new Pods using the template
4. Actual > Desired → deletes excess Pods
5. Loop runs continuously
```

The ReplicaSet **does not** care which specific Pods are running — only that the count matches and the selector matches.

## ReplicaSet Definition

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-rs
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web          # Must match template labels exactly
  template:
    metadata:
      labels:
        app: web        # Must match selector
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

> [!warning]
> The `selector.matchLabels` and `template.metadata.labels` **must match**. If they don't, the ReplicaSet will be rejected by the API server.

## Label Selector — The Critical Detail

The ReplicaSet uses the `selector` to **adopt or orphan Pods**. Any Pod in the same namespace with matching labels will be claimed by the ReplicaSet — even pre-existing Pods not created by it.

```yaml
selector:
  matchLabels:
    app: web      # Simple equality match
```

```yaml
selector:
  matchExpressions:
  - key: app
    operator: In
    values: [web, frontend]   # More expressive matching
```

> [!warning] Exam Trap
> If you manually create a Pod with labels matching a ReplicaSet's selector, the RS will **immediately adopt it** and may delete another Pod to maintain the replica count.

## Deployment ↔ ReplicaSet Relationship

When a [[Deployments|Deployment]] is updated (e.g. new image), it:

```
1. Creates a NEW ReplicaSet with the updated Pod template
2. Scales up the new RS gradually
3. Scales down the old RS gradually
4. Keeps the old RS (scaled to 0) for rollback
```

```bash
# See this in action
kubectl get replicasets
# NAME                   DESIRED   CURRENT   READY
# web-deployment-abc123  3         3         3    ← current
# web-deployment-def456  0         0         0    ← previous (rollback target)
```

## Key Commands

```bash
# Create from file
kubectl apply -f replicaset.yaml

# List ReplicaSets
kubectl get replicasets
kubectl get rs        # Short form

# Describe a ReplicaSet
kubectl describe rs web-rs

# Scale a ReplicaSet
kubectl scale rs web-rs --replicas=5

# Delete ReplicaSet (also deletes its Pods)
kubectl delete rs web-rs

# Delete ReplicaSet but keep Pods (orphan)
kubectl delete rs web-rs --cascade=orphan

# Check which RS owns a Pod
kubectl get pod <pod-name> -o yaml | grep ownerReferences -A 5
```

## Common Issues / Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| Pods not created | Selector doesn't match template labels | Ensure `matchLabels` == `template.metadata.labels` |
| RS adopts unexpected Pods | Pre-existing Pods match selector | Change labels on those Pods or update selector |
| RS stuck at wrong count | Pods failing to schedule | Check `kubectl describe rs` Events section |
| Deleting RS doesn't remove Pods | Used `--cascade=orphan` | Delete Pods manually or omit the flag |
| RS not scaling up | Node resource pressure | Check `kubectl describe pod` for scheduling errors |

## Related Notes

- [[Deployments]] — Wraps ReplicaSets; use this instead of raw RS in practice
- [[Pods]] — What the ReplicaSet creates and manages
- [[kube-controller-manager]] — Contains the ReplicaSet Controller
- [[Labels]] — Selectors are how RS identifies and adopts Pods
- [[Autoscaling]] — HPA can target ReplicaSets directly (though Deployments are more common)

## Key Mental Model

A ReplicaSet is a **headcount enforcer**. It doesn't care about identity — it only cares about numbers. As long as the right count of Pods with the right labels exists, it's satisfied. [[Deployments]] are the manager that tells the ReplicaSet *which workers to hire* when the job description changes.
