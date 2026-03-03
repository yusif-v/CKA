---
tags: [cka/workloads, workloads]
aliases: [Deployment, Rolling Update, Rollback]
---

# Deployments

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[kube-controller-manager]], [[kube-scheduler]], [[Autoscaling]], [[Services]]

## Overview

A **Deployment** is the standard way to manage **stateless applications** in Kubernetes. It provides declarative updates, scaling, rolling updates, and rollbacks. Internally, a Deployment manages **ReplicaSets**, which in turn manage **[[Pods]]**.

## Deployment Hierarchy

```
Deployment
  └── ReplicaSet (current)
        └── Pod 1
        └── Pod 2
        └── Pod 3
  └── ReplicaSet (previous — kept for rollback)
```

Changing the Pod template creates a new ReplicaSet.

## Basic Deployment Definition

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deployment
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
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
            cpu: "500m"
            memory: "256Mi"
```

## Update Strategies

### RollingUpdate (default)

Zero-downtime updates, Pods replaced gradually:

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1    # Max pods unavailable during update
    maxSurge: 1          # Max extra pods created during update
```

### Recreate

All old Pods deleted before new ones created (causes downtime):

```yaml
strategy:
  type: Recreate
```

## Key Commands

```bash
# Create deployment
kubectl create deployment web --image=nginx --replicas=3

# Apply from file
kubectl apply -f deployment.yaml

# Scale
kubectl scale deployment web --replicas=5

# Update image (triggers rolling update)
kubectl set image deployment/web nginx=nginx:1.26

# Check rollout status
kubectl rollout status deployment/web

# View rollout history
kubectl rollout history deployment/web

# Rollback to previous version
kubectl rollout undo deployment/web

# Rollback to specific revision
kubectl rollout undo deployment/web --to-revision=2

# Pause rollout (for canary-style updates)
kubectl rollout pause deployment/web

# Resume rollout
kubectl rollout resume deployment/web

# Get all deployment info
kubectl describe deployment web
kubectl get replicasets
kubectl get pods -l app=web
```

## Autoscaling Integration

```bash
# Create HPA for deployment
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=50
```

See [[Autoscaling]] for full details.

## Common Issues / Troubleshooting

- **Pods stuck in old version** → rollout may be paused; `kubectl rollout resume`
- **Rollout stuck** → maxUnavailable=0 and maxSurge=0 is invalid; check strategy
- **Image pull failure** → all new pods fail; rollback with `kubectl rollout undo`
- **Selector immutable error** → Deployment selector cannot be changed after creation; delete and recreate
- **Pods not matching service** → verify Deployment labels match [[Services]] selector

## Related Notes

- [[Pods]] — What Deployments ultimately manage
- [[kube-controller-manager]] — Contains the Deployment Controller
- [[Services]] — Route traffic to Deployment pods
- [[Autoscaling]] — HPA works with Deployments
- [[Labels]] — Selector and template labels must match

## Key Mental Model

A Deployment is a **control system**: you declare what you want, and Kubernetes figures out how to keep it true. ReplicaSets are the mechanics. Pods are disposable workers. Deployments turn chaos into **predictable, updatable motion**.
