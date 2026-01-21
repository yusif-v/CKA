# Deployment

## Overview

A **Deployment** is a higher-level Kubernetes object that manages **stateless applications**.
It provides:
- Declarative updates
- Scaling
- Rolling updates
- Rollbacks

Internally, a Deployment manages **[[ReplicaSet]]**, which in turn manage **[[Pods]]**.

## What a Deployment Manages

- Desired number of replicas
- Pod template (image, env, resources, etc.)
- Update strategy
- History of revisions

You **never manage Pods directly** when using Deployments.

## Basic Deployment Definition

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

## How Deployments Work (Under the Hood)

1. You apply a Deployment
2. Kubernetes creates a **ReplicaSet**
3. ReplicaSet creates **Pods**
4. Deployment continuously reconciles desired state

Change the Pod template → **new ReplicaSet is created**

🔗 Related:
- [[ReplicaSet]]
- [[Rolling Updates]]
- [[Rollbacks]]

## Creating a Deployment
### Imperative

```bash
kubectl create deployment web --image=nginx
```

### Declarative

```bash
kubectl apply -f deployment.yaml
```

## Scaling a Deployment

```bash
kubectl scale deployment web-deployment --replicas=5
```

Or declaratively:

```yaml
spec:
  replicas: 5
```

🔗 Related:

- [[Autoscaling]]
- [[Horizontal Pod Autoscaler]]

## Rolling Updates

Default strategy: **RollingUpdate**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

- Zero downtime updates
- Gradual Pod replacement

Check rollout status:

```bash
kubectl rollout status deployment web-deployment
```

## Rollbacks

View rollout history:

```bash
kubectl rollout history deployment web-deployment
```

Rollback to previous version:

```bash
kubectl rollout undo deployment web-deployment
```

🔗 Related:

- [[Rollbacks]]
- [[Rollouts]]

## Updating a Deployment

Update image:

```bash
kubectl set image deployment web-deployment nginx=nginx:1.26
```

This triggers a **new ReplicaSet**.

## Observability

```bash
kubectl get deployments
kubectl describe deployment web-deployment
kubectl get rs
kubectl get pods
```

## Best Practices

- Use Deployments for **stateless workloads**
- Always define **resource requests and limits**
- Use labels consistently
- Combine with HPA for scaling
- Avoid manual Pod edits

## Key Mental Model

A Deployment is a **control system**:
- You declare **what you want**
- Kubernetes figures out **how to keep it true**
- ReplicaSets are the mechanics
- Pods are disposable workers

Deployments turn chaos into **predictable motion**.