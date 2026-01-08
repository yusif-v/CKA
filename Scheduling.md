# Scheduling
## Overview

**Scheduling** is the process of assigning a **Pod to a Node**.
Until a Pod is scheduled, it stays in Pending.

The component responsible is **[[kube-scheduler]]**.

## Scheduling Flow

1. Pod is created (no nodeName)
2. [[kube-apiserver]] stores Pod spec
3. [[kube-scheduler]] watches for unscheduled Pods
4. Scheduler:
    - Filters Nodes (constraints)
    - Scores remaining Nodes
5. Best Node chosen
6. Pod is bound to Node
7. [[kubelet]] starts the Pod

```
Pod → Scheduler → Node → Kubelet
```

## Manual Scheduling

You can bypass the scheduler by specifying nodeName.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: worker-1
  containers:
  - name: nginx
    image: nginx
```

Scheduler is skipped entirely.
Used rarely, but shows up in exams.

## Node Selection Mechanisms
### nodeSelector (simple)

```yaml
spec:
  nodeSelector:
    disktype: ssd
```

Hard requirement.

### Node Affinity (advanced)

Replaces nodeSelector.

#### Required (hard)

```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: disktype
          operator: In
          values:
          - ssd
```

#### Preferred (soft)

```yaml
affinity:
  nodeAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 1
      preference:
        matchExpressions:
        - key: zone
          operator: In
          values:
          - eu-central
```

## Taints and Tolerations

Control **which Pods may run on Nodes**.

### Taint a Node

```bash
kubectl taint nodes node1 key=value:NoSchedule
```

### Toleration in Pod

```yaml
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
```

Effect types:
- NoSchedule
- PreferNoSchedule
- NoExecute

## Resource-Based Scheduling

Scheduler considers:
- CPU requests
- Memory requests
- Extended resources (GPUs)

Example:

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
```

If requests exceed Node capacity → Pod stays Pending.

## Pod Priority & Preemption

Higher priority Pods can **evict lower priority Pods**.

### PriorityClass

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
description: "Critical workloads"
```

Pod:

```yaml
priorityClassName: high-priority
```

## **Scheduler Profiles (Advanced)**

kube-scheduler supports multiple profiles:
- Different plugins
- Different scoring rules

## Common Scheduling Failures

- No matching node labels
- Missing toleration
- Insufficient CPU / memory
- Node is cordoned or drained

Check:

```bash
kubectl describe pod <pod-name>
```

Look for FailedScheduling events.

## Key Mental Model

Scheduler:
- **Chooses a Node**
- **Does not run containers**
- **Does not monitor runtime**

Once scheduled, the scheduler is done.
From there on, the kubelet carries the torch.