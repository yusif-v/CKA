## Overview

A **Replication Controller (RC)** ensures that a specified number of **Pod replicas** are running at any given time. If Pods fail, are deleted, or nodes go down, the controller creates new Pods to maintain the desired replica count.

Replication Controller is largely **superseded by [[ReplicaSet Controller]]**, but it still exists for backward compatibility.

## Core Responsibilities

- Maintain the desired number of Pod replicas
- Create Pods when replicas are missing
- Delete excess Pods when replicas exceed desired state
- React to Pod and Node failures

## **How It Works**

- Watches Pods via the kube-apiserver
- Uses **label selectors** to manage Pods
- Continuously reconciles:
    - spec.replicas vs actual running Pods
- Acts through kube-apiserver only

## Pod Selection

- Uses **equality-based selectors only**
- Example:
```yaml
selector:
  app: web
```

Limitation:
- Cannot use set-based selectors (in, notin, exists)

## Update Behavior

- No native rolling update support
- Updating a Pod template requires:
    - Manual Pod deletion
    - Or creating a new Replication Controller
- This limitation led to the creation of ReplicaSets and Deployments

## Interaction with Other Components

- Runs inside [[kube-controller-manager]]
- Creates Pods via kube-apiserver
- Does not interact with kubelet directly
- Scheduling handled by [[kube-scheduler]]

## Configuration Example

```yaml
apiVersion: v1
kind: ReplicationController
metadata:
  name: web-rc
spec:
  replicas: 3
  selector:
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
    - availableReplicas
- View status:
```bash
kubectl get rc
kubectl describe rc <name>
```

## Limitations

- Legacy object
- No rolling updates
- No revision history
- Less flexible selectors

## Relationship to Other Workloads

- Predecessor to:
    - [[ReplicaSet Controller]]
    - [[Deployment]]
- Modern clusters use Deployments instead