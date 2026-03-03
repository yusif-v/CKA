---
tags: [cka/workloads, workloads]
aliases: [Pod Scheduling, Node Assignment]
---

# Scheduling

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[kube-scheduler]], [[Node Affinity]], [[Taints]], [[Pods]], [[Resource Limits]]

## Overview

**Scheduling** is the process of assigning a [[Pods|Pod]] to a Node. Until a Pod is scheduled, it stays in `Pending`. The [[kube-scheduler]] performs scheduling by filtering feasible Nodes and scoring them to pick the best fit.

## Scheduling Flow

```
1. Pod created (no nodeName set)
2. kube-apiserver stores Pod spec
3. kube-scheduler watches for unscheduled Pods
4. Scheduler: Filters Nodes → Scores Nodes → Selects best
5. Pod is bound to Node (nodeName set)
6. kubelet on that Node picks it up and starts containers
```

## Manual Scheduling (Bypass Scheduler)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: worker-1    # Scheduler bypassed entirely
  containers:
  - name: nginx
    image: nginx
```

## Node Selection Mechanisms

### nodeSelector (Simple)

Hard requirement — Pod only schedules on matching Nodes:

```yaml
spec:
  nodeSelector:
    disktype: ssd
```

Label a Node:
```bash
kubectl label node worker-1 disktype=ssd
```

### Node Affinity (Advanced)

See [[Node Affinity]] for full details. Supports both hard (required) and soft (preferred) rules.

### Taints and Tolerations

See [[Taints]] for full details. Nodes repel Pods that don't have matching tolerations.

### Resource-Based Scheduling

Scheduler considers resource **requests** (not limits):

```yaml
resources:
  requests:
    cpu: "500m"
    memory: "256Mi"
```

If requests exceed all Node capacity → Pod stays **Pending**.

## Pod Priority and Preemption

Higher priority Pods can evict lower priority Pods:

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 100000
globalDefault: false
```

```yaml
spec:
  priorityClassName: high-priority
```

## Topology Spread Constraints

Distribute Pods evenly across zones/nodes:

```yaml
spec:
  topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: kubernetes.io/hostname
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: web
```

## Key Commands

```bash
# Check why a pod is pending
kubectl describe pod <pod-name>
# Look for: Events → FailedScheduling

# Check node labels
kubectl get nodes --show-labels

# Label a node
kubectl label node worker-1 disktype=ssd

# Check node capacity
kubectl describe node worker-1
# Look for: Capacity, Allocatable, Allocated resources

# List pending pods
kubectl get pods --field-selector=status.phase=Pending

# Check taints on a node
kubectl describe node worker-1 | grep Taint
```

## Common Issues / Troubleshooting

- **Pod stuck Pending** → run `kubectl describe pod` → look for `FailedScheduling` event
- **Insufficient cpu/memory** → Pod requests exceed Node allocatable; scale Node or lower requests
- **No nodes match nodeSelector** → label mismatch; `kubectl get nodes --show-labels`
- **Taint not tolerated** → Node taint blocks Pod; add toleration or remove taint
- **All nodes cordoned** → `kubectl get nodes` shows `SchedulingDisabled`

## Related Notes

- [[kube-scheduler]] — The component that implements scheduling
- [[Node Affinity]] — Advanced scheduling rules
- [[Taints]] — Node-level scheduling repulsion
- [[Resource Limits]] — Requests influence scheduling
- [[Labels]] — nodeSelector relies on node labels

## Key Mental Model

Scheduling is **matchmaking at scale**: the scheduler finds the best Node for each Pod based on hard constraints (must-have) and soft preferences (nice-to-have). Once matched, the scheduler steps away and [[kubelet]] takes over.
