## Overview

The **ReplicaSet Controller** ensures that a specified number of **Pod replicas** are running at any given time. It continuously reconciles the desired replica count defined in a ReplicaSet with the actual number of Pods in the cluster.

ReplicaSets are the **successor to [[Replication Controller]]** and are most commonly managed indirectly by [[Deployment Controller]].

## Core Responsibilities

- Maintain desired Pod replica count
- Create Pods when replicas are missing
- Delete excess Pods when replicas exceed desired state
- Adopt or release Pods based on selector matching
  
## How It Works

- Watches ReplicaSet and Pod objects via kube-apiserver
- Uses **label selectors** to identify managed Pods
- Compares:
    - spec.replicas vs actual Pods   
- Reconciles state through kube-apiserver only

## Pod Selection
- Supports **set-based label selectors**
- Examples:
```bash
selector:
  matchLabels:
    app: web
```

```bash
selector:
  matchExpressions:
  - key: tier
    operator: In
    values:
    - frontend
    - backend
```

This flexibility is a major improvement over Replication Controllers.

## Update Behavior

- ReplicaSet does **not** perform rolling updates on its own
- Updating the Pod template creates **new Pods**, but does not manage rollout strategy
- Rolling updates are handled by [[Deployment Controller]]

## Interaction with Other Components

- Runs inside [[kube-controller-manager]]
- Creates and deletes Pods via [[kube-apiserver]]
- Scheduling performed by [[kube-scheduler]]
- Execution handled by [[kubelet]]

## Adoption and Ownership

- Uses **ownerReferences** to track Pod ownership
- Can adopt orphaned Pods that match its selector
- Deployments create and manage multiple ReplicaSets during rollouts

## Configuration Example

```bash
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

## Monitoring and Status

- Status fields:
    - replicas
    - readyReplicas
    - availableReplicas
- View status:
```bash
kubectl get rs
kubectl describe rs <name>
```

## Common Scenarios

- Ensuring fixed replica count
- Backend object for Deployments
- Recovering from Pod or Node failure

## Relationship to Other Workloads

- Replaces [[Replication Controller]]
- Managed by [[Deployment]]
- Parent controller: [[Deployment Controller]]
