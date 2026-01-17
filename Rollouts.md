# Rollouts
## Overview

A **Rollout** is the process by which Kubernetes **applies changes to a workload over time**.

In practice, rollout usually refers to:
- Deploying a new version
- Monitoring its progress
- Managing updates and failures

Rollouts are most commonly associated with [[Deployments]].

## What Triggers a Rollout

A rollout starts when the **Pod template changes**, such as:
- Container image update
- Environment variable change
- Resource request/limit change
- Labels or annotations change (template-level)

Changes outside the Pod template do **not** trigger a rollout.

## Rollout Lifecycle

1. Deployment spec is updated
2. New [[ReplicaSet]] is created
3. Pods are gradually updated
4. Old ReplicaSet is scaled down
5. Rollout completes or pauses

This process is controlled by the [[Deployment Controller]].

## Rollout Strategies

Common strategies include:
- [[Rolling Updates]] (default)
- Recreate (terminate all, then create new)

## Managing Rollouts

Check rollout status:

```bash
kubectl rollout status deployment <deployment-name>
```

Pause a rollout:

```bash
kubectl rollout pause deployment <deployment-name>
```

Resume a rollout:

```bash
kubectl rollout resume deployment <deployment-name>
```

## Rollout History

Each rollout creates a **revision**.

View history:

```bash
kubectl rollout history deployment <deployment-name>
```

View a specific revision:

```bash
kubectl rollout history deployment <deployment-name> --revision=3
```

## Failed Rollouts

A rollout may fail due to:
- Pods failing readiness probes
- Image pull errors
- Resource constraints
- Misconfiguration

When failure occurs:
- Rollout pauses
- Old Pods may remain running
- Manual action is required

## Rollout vs Rollback

Rollout:
- Moving **forward** to a new version

Rollback:
- Moving **back** to a previous version

They are complementary operations.

## Rollouts Beyond Deployments

Rollout concepts also apply to:
- [[DaemonSets]] (node-by-node)
- [[StatefulSets]] (ordered updates)

Behavior varies by controller.

## Best Practices

- Monitor rollouts actively
- Use readiness probes
- Keep revision history
- Pause rollouts during investigations

## Key Mental Model

A rollout is **change under supervision**.

Kubernetes doesn’t flip a switch.
It walks the system forward, watching each step —
ready to stop if the ground gives way.