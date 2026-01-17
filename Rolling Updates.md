# Rolling Updates
## Overview

A **Rolling Update** is a deployment strategy that **updates Pods gradually**, without taking the application offline.

Old Pods are terminated and new Pods are created **in controlled batches**.

This is the default update strategy for [[Deployments]].

## Why Rolling Updates Exist

They allow:
- Zero or minimal downtime
- Controlled risk during releases
- Continuous availability

Instead of flipping everything at once, Kubernetes changes reality **a little at a time**.

## Components Involved

Rolling Updates rely on:
- [[Deployment Controller]]
- [[ReplicaSet]]
- [[kube-scheduler]]
- [[kubelet]]

The Deployment Controller orchestrates the process.

## How Rolling Updates Work

1. A Deployment spec changes (e.g., new image)
2. A **new ReplicaSet** is created
3. Pods are gradually shifted:
    - New Pods are created
    - Old Pods are terminated    
4. Desired availability is maintained

At no point does Kubernetes “stop the app”.

## RollingUpdate Strategy

Defined in the Deployment spec:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

## Key Parameters
### maxSurge

- Maximum number of **extra Pods** above desired replicas
- Can be absolute or percentage

Example:

```yaml
maxSurge: 25%
```

### maxUnavailable

- Maximum number of Pods that can be unavailable
- Controls availability during update


Example:

```yaml
maxUnavailable: 0
```

Guarantees zero downtime.

## Update Example

Change image:

```bash
kubectl set image deployment/web nginx=nginx:1.25
```

Check rollout status:

```bash
kubectl rollout status deployment/web
```

## Rollback

Rollback to previous revision:

```bash
kubectl rollout undo deployment/web
```

Rollback to a specific revision:

```bash
kubectl rollout undo deployment/web --to-revision=2
```

## Rollout History

View rollout history:

```bash
kubectl rollout history deployment/web
```

Each revision maps to a ReplicaSet.

## Failure Handling

If new Pods fail:
- Rollout pauses
- Old Pods stay running
- Manual intervention may be required

Kubernetes favors **safety over speed**.

## DaemonSet Rolling Updates

[[DaemonSets]] also support rolling updates:
- One Node at a time
- Controlled by maxUnavailable

But behavior differs slightly.

## Best Practices

- Set maxUnavailable: 0 for critical services
- Use readiness probes
- Test images before rollout
- Monitor rollout status

## Key Mental Model

Rolling Updates are **controlled evolution**.

Kubernetes doesn’t replace the organism.
It replaces cells — carefully — until the whole body is new.