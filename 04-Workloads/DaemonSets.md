---
tags: [cka/workloads, workloads]
aliases: [DaemonSet, Node-level workload]
---

# DaemonSets

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[kube-controller-manager]], [[Taints]], [[Node Affinity]], [[kubelet]]

## Overview

A **DaemonSet** ensures that **a copy of a Pod runs on every Node** (or a selected subset) in the cluster. As Nodes are added or removed, the DaemonSet automatically adds or removes Pods. DaemonSets are used for **node-level infrastructure services**.

> [!tip] Exam Tip
> `kubectl drain` with `--ignore-daemonsets` flag is heavily tested — DaemonSet pods are not evicted during node maintenance.

## Common Use Cases

- Log collectors (Fluentd, Filebeat)
- Monitoring agents (Node Exporter, Datadog)
- Network plugins (CNI agents)
- Storage daemons
- Security agents
- [[kube-proxy]] itself runs as a DaemonSet

## How DaemonSets Work

```
1. DaemonSet object created
2. DaemonSet Controller (inside kube-controller-manager) watches Node events
3. Creates one Pod per eligible Node
4. kubelet on each Node starts the Pod
5. New Node joins → DaemonSet Pod automatically created
6. Node removed → DaemonSet Pod automatically deleted
```

Unlike [[Deployments]], you **do not** specify `replicas` — the count is determined by Node count.

## DaemonSet Definition

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-agent
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: node-agent
  template:
    metadata:
      labels:
        app: node-agent
    spec:
      tolerations:
      - operator: Exists    # Run on ALL nodes including control-plane
      containers:
      - name: agent
        image: monitoring-agent:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "200m"
            memory: "256Mi"
```

## Node Selection

DaemonSets can be restricted to specific Nodes using:

```yaml
# Simple nodeSelector
spec:
  template:
    spec:
      nodeSelector:
        disktype: ssd

# Advanced Node Affinity
spec:
  template:
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values: [linux]
```

## Taints and DaemonSets

To run on control-plane nodes (which have taints), add tolerations:

```yaml
tolerations:
- key: node-role.kubernetes.io/control-plane
  operator: Exists
  effect: NoSchedule
```

Or tolerate ALL taints:

```yaml
tolerations:
- operator: Exists
```

## Update Strategy

```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 1    # Update one node at a time
```

## Key Commands

```bash
# List DaemonSets
kubectl get daemonsets
kubectl get daemonsets -n kube-system

# Describe DaemonSet
kubectl describe daemonset node-agent

# Check DaemonSet pods (one per node)
kubectl get pods -l app=node-agent -o wide

# Drain node (ignores DaemonSet pods)
kubectl drain <node> --ignore-daemonsets

# Check rollout
kubectl rollout status daemonset/node-agent
```

## Common Issues / Troubleshooting

- **Not running on some nodes** → check [[Taints]] and tolerations; add `operator: Exists` toleration
- **Not running on control-plane** → control-plane has `NoSchedule` taint; add toleration
- **Too many resources** → running on every node multiplies resource usage; set appropriate requests/limits
- **After drain, pod not evicted** → correct behavior; DaemonSet pods skip drain (use `--ignore-daemonsets`)

## Related Notes

- [[Pods]] — What DaemonSets create on each node
- [[Taints]] — Control which nodes DaemonSet pods run on
- [[Node Affinity]] — Advanced node selection for DaemonSets
- [[OS Upgrade]] — DaemonSet pods not evicted during drain
- [[kube-controller-manager]] — Contains the DaemonSet controller

## Key Mental Model

DaemonSet = **exactly one Pod per Node**. While [[Deployments]] scale by replicas, DaemonSets scale by Nodes. They are essential for **infrastructure-level workloads** that must exist everywhere, not just application logic.
