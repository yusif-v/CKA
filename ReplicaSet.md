# ReplicaSet
## Overview

A **ReplicaSet** ensures that a **specified number of identical Pods** are running at any given time.

It replaces the older [[Replication Controller]] and is the **foundation used by [[Deployments]]**.

## Purpose

ReplicaSets are responsible for:
- Maintaining desired Pod count
- Recreating Pods if they crash or are deleted
- Managing Pods using **label selectors**

They do **not** handle rolling updates or versioning on their own.

## How ReplicaSets Work

1. [[ReplicaSet Controller]] (inside [[kube-controller-manager]]) watches:
    - Pods
    - ReplicaSet objects
2. It compares:
    - Desired replicas
    - Actual running Pods
3. It creates or deletes Pods to reconcile the difference

## Key Difference from Replication Controller

ReplicaSet supports **set-based selectors**, while Replication Controller supports only equality-based selectors.

Example selector:

```yaml
selector:
  matchExpressions:
  - key: app
    operator: In
    values:
    - web
    - api
```

## ReplicaSet Definition File

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: web-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx
```

## ReplicaSet vs Deployment

ReplicaSets:
- Ensure Pod count
- Do not manage updates
- Are usually **not created directly**

Deployments:
- Create and manage ReplicaSets
- Handle rolling updates and rollbacks
- Are preferred for application workloads

## Scaling a ReplicaSet

```bash
kubectl scale rs web-rs --replicas=5
```

Or by editing the manifest:

```yaml
spec:
  replicas: 5
```

## Observability and Debugging

List ReplicaSets:

```bash
kubectl get rs
```

Describe a ReplicaSet:

```bash
kubectl describe rs web-rs
```

View controlled Pods:

```bash
kubectl get pods -l app=web
```

## Limitations

- No rolling updates
- No rollback support
- Manual image updates require Pod recreation

This is why ReplicaSets are rarely used directly.

## Key Mental Model

ReplicaSet = **quantity enforcer**

If a Pod dies, the ReplicaSet doesn’t ask why.

It simply notices the count is wrong—and fixes reality.