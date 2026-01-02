## Overview

The **Deployment Controller** is a Kubernetes controller responsible for managing **Deployment objects**. It ensures that the actual state of the cluster matches the desired state defined in a Deployment by creating, updating, and scaling **ReplicaSets**.

It enables **rolling updates**, **rollbacks**, and **revision history** by orchestrating multiple ReplicaSets over time.

## Core Responsibilities

- Create ReplicaSets for Deployments
- Scale ReplicaSets up or down during updates
- Manage rollout strategy (RollingUpdate or Recreate)
- Track revision history
- Perform rollbacks on request or failure

## How It Works

- Watches Deployment and ReplicaSet objects via kube-apiserver
- Compares:
    - Deployment spec
    - Existing ReplicaSets
- Determines the **active ReplicaSet**
- Reconciles replicas according to update strategy
- Writes all changes through kube-apiserver

Hierarchy:

```
Deployment Controller
  └── Deployment
        └── ReplicaSet
              └── Pod
```

## Rolling Update Logic
### RollingUpdate Strategy

- Creates a new ReplicaSet with updated Pod template
- Gradually scales:
    - New ReplicaSet up
    - Old ReplicaSet down
- Controlled by:
    - maxSurge
    - maxUnavailable

### Recreate Strategy

- Scales old ReplicaSet to zero
- Creates new ReplicaSet afterward
- Causes downtime

## Revision Management

- Each ReplicaSet represents a **revision**
- Revisions tracked via annotations
- Old ReplicaSets retained for rollback
- Controlled by:

```yaml
revisionHistoryLimit: 10
```

## Rollback Behavior

- On rollback request:
    - Selects previous ReplicaSet
    - Scales it up
    - Scales current ReplicaSet down
- Triggered manually via kubectl
- No direct Pod manipulation

## Interaction with Other Components

- Runs inside [[kube-controller-manager]]
- Manages [[ReplicaSet Controller]]
- Creates and scales Pods indirectly
- Scheduling by [[kube-scheduler]]
- Execution by [[kubelet]]
- All state changes go through [[kube-apiserver]]

## Failure Handling

- Failed Pods trigger ReplicaSet reconciliation
- Rollout pauses if progress deadlines exceeded
- Deployment marked failed if conditions not met

## Monitoring and Status

- Deployment conditions:
    - Progressing
    - Available
    - ReplicaFailure
- Observed via:

```bash
kubectl describe deployment <name>
kubectl rollout status deployment <name>
```

## Common Scenarios

- Zero-downtime application updates
- Controlled rollbacks
- Progressive scaling during releases
- Canary-style workflows (manual)