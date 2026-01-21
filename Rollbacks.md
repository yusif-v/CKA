# Rollback

## Overview

A **Rollback** reverts a Kubernetes workload to a **previously known-good state** after a failed or problematic change.

Rollbacks are typically used with [[Deployments]] to recover from a **bad rollout**.

## Why Rollbacks Matter

- Restore service availability quickly
- Minimize downtime during failed updates
- Reduce risk when deploying new versions

Think of rollbacks as the **emergency brake** during [[Rolling Updates]] or [[Rollouts]].

## How Rollbacks Work

1. Each Deployment update creates a new [[ReplicaSet]] revision
2. Older ReplicaSets are retained (based on revisionHistoryLimit)
3. Rollback switches the active Pods to a previous ReplicaSet
4. New Pods are terminated and replaced by the older version

The [[Deployment Controller]] handles the mechanics.

## Rollback Commands
### Rollback to previous revision

```bash
kubectl rollout undo deployment <deployment-name>
```

### Rollback to a specific revision

```bash
kubectl rollout undo deployment <deployment-name> --to-revision=2
```

## Viewing Rollout History

```bash
kubectl rollout history deployment <deployment-name>
```

Check details of a revision:

```bash
kubectl rollout history deployment <deployment-name> --revision=2
```

Each revision corresponds to a [[ReplicaSet]].

## What Gets Rolled Back

- Pod template (image, env, resources)
- Labels and annotations (template-level)
- ReplicaSet configuration

**Not rolled back**:
- PersistentVolumes or stored data
- ConfigMaps or [[Secrets]] (unless explicitly managed)

## Rollback vs Restart

- **Rollback**: returns to a previous version
- **Restart**: recreates Pods using the **same version**

These are fundamentally different operations.

## Best Practices

- Use [[Deployments]] for workloads that may need rollback
- Maintain sufficient revisionHistoryLimit
- Monitor rollouts actively to detect issues early
- Test rollback procedures in non-production environments

## Key Mental Model

A rollback is **Kubernetes’ safety net**:
it remembers what worked before and allows you to **rewind the system safely** if a rollout goes wrong.

It works hand-in-hand with [[Rollouts]] and [[Rolling Updates]] to keep your cluster stable.