## Overview

A **Deployment** is a higher-level Kubernetes workload object that manages **stateless applications**. It provides **declarative updates**, **scaling**, and **rollback capabilities** by managing one or more [[ReplicaSet Controller]] objects.

You almost never manage ReplicaSets directly in production; Deployments do that orchestration for you.

## Core Responsibilities

- Manage ReplicaSets
- Perform rolling updates
- Enable rollbacks to previous versions
- Scale applications declaratively
- Ensure desired Pod state is maintained

## How Deployments Work

- You define a desired state in the Deployment spec
- The [[Deployment Controller]] creates a ReplicaSet
- The ReplicaSet creates Pods
- On updates, a **new ReplicaSet** is created
- Old ReplicaSets are scaled down gradually (based on strategy)

Hierarchy:

```yaml
Deployment
  └── ReplicaSet
        └── Pod
```

## Update Strategies

### RollingUpdate (default)

- Gradually replaces old Pods with new ones
- Controlled by:
    - maxSurge
    - maxUnavailable

Example:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

### Recreate

- Terminates all old Pods before creating new ones
- Causes downtime

```yaml
strategy:
  type: Recreate
```

## Scaling

- Adjusts replicas in the active ReplicaSet
- Manual or automated (via HPA)

```bash
kubectl scale deployment web --replicas=5
```

## Rollouts and Rollbacks
### Rollout

- Triggered when:
    - Image changes
    - Pod template changes
- Each rollout creates a new ReplicaSet

```bash
kubectl rollout status deployment web
```

### Rollback

- Reverts to a previous ReplicaSet revision

```bash
kubectl rollout undo deployment web
```

## Revision History

- Stored as multiple ReplicaSets
- Controlled by:

```yaml
revisionHistoryLimit: 10
```

Old ReplicaSets kept for rollback purposes.

## Interaction with Other Components

- Managed by [[Deployment Controller]]
- Uses [[ReplicaSet Controller]] for Pod replication
- Scheduling handled by [[kube-scheduler]]
- Execution handled by [[kubelet]]
- All state changes go through [[kube-apiserver]]

## Deployment Definition Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
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
        image: nginx:1.25
        ports:
        - containerPort: 80
```

## Monitoring and Status

- Status fields:
    - replicas
    - updatedReplicas
    - readyReplicas
    - availableReplicas

```bash
kubectl get deployments
kubectl describe deployment <name>
```

## Common Use Cases

- Stateless web applications
- APIs and microservices
- Continuous delivery workflows
- Applications requiring zero-downtime updates

## Limitations

- Not ideal for stateful workloads
- No stable Pod identity
- For stateful apps, use [[StatefulSet]]