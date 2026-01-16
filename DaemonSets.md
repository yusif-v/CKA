# DaemonSets
## Overview

A **DaemonSet** ensures that **a copy of a Pod runs on every Node** (or a selected set of Nodes) in the cluster.

As Nodes are added or removed, the DaemonSet **automatically adds or removes Pods**.

DaemonSets are commonly used for **node-level system services**.

## What DaemonSets Are Used For

Typical use cases include:

- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Node Exporter)
- Network plugins (CNI)
- Storage daemons
- Security agents

These workloads must run **once per Node**, not per application.

## How DaemonSets Work

1. A DaemonSet object is created
2. [[DaemonSet Controller]] (inside [[kube-controller-manager]]):
    - Watches Node events
    - Creates one Pod per eligible Node
3. [[kubelet]] on each Node starts the Pod

Unlike [[Deployments]] or [[ReplicaSets]], you do **not** specify replicas.

## Scheduling Behavior

- DaemonSet Pods **bypass normal replica scheduling**
- Pods are automatically scheduled onto Nodes
- Node selection can still be controlled using:
    - [[Node Selectors]]
    - [[Node Affinity]]
    - [[Taints]] and [[Tolerations]]

## Taints and DaemonSets

DaemonSets often tolerate Node taints automatically.
Example toleration:

```
tolerations:
- operator: Exists
```

This allows DaemonSet Pods to run on:
- Master / control-plane Nodes
- Special-purpose Nodes

## Resource Management

DaemonSet Pods support:
- [[Resource Requests]]
- [[Resource Limits]]

Requests are especially important to prevent Node overcommitment since every Node runs one copy.

## Update Strategies

DaemonSets support rolling updates:

```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1
```

This updates Pods node-by-node.

## DaemonSet Definition File

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      containers:
      - name: agent
        image: nginx
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
```

## Observability and Debugging

Check DaemonSet status:

```bash
kubectl get daemonsets
```

Inspect details:

```bash
kubectl describe daemonset <name>
```

Check Pods per Node:

```bash
kubectl get pods -o wide
```

## Key Mental Model

DaemonSet =
**exactly one Pod per Node** (by default)

Think:
- Deployments scale by **replicas**
- DaemonSets scale by **Nodes**

This makes them essential for **infrastructure-level workloads**, not application logic.