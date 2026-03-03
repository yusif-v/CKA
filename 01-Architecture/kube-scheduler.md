---
tags: [cka/architecture, architecture]
aliases: [Scheduler, Pod Scheduler]
---

# kube-scheduler

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[Scheduling]], [[Node Affinity]], [[Taints]], [[Pods]]

## Overview

The **kube-scheduler** is the control-plane component responsible for **assigning [[Pods]] to Nodes**. It watches for newly created Pods without a `nodeName` and selects the most suitable Node based on resource availability, constraints, and scheduling policies.

The scheduler only **writes the binding decision** back to [[kube-apiserver]] — it does not create Pods or start containers.

## Scheduling Workflow

```
1. Watch kube-apiserver for unscheduled Pods
2. Build list of feasible Nodes (Filtering)
3. Score feasible Nodes (Scoring)
4. Select highest-scoring Node
5. Bind Pod to Node via kube-apiserver
6. kubelet picks it up and starts the Pod
```

## Scheduling Phases

### Filtering (Predicates) — Hard Constraints

Removes Nodes that **cannot** run the Pod:
- Insufficient CPU or memory (vs [[Resource Limits|resource requests]])
- [[Node Affinity]] required rules mismatch
- [[Taints]] not tolerated
- Port conflicts
- Volume topology constraints

### Scoring (Priorities) — Soft Preferences

Ranks remaining Nodes:
- Resource balance
- Preferred [[Node Affinity]]
- Pod/Anti-affinity preferences
- Topology spread constraints

## Scheduling Constraints Supported

| Mechanism | Hard/Soft | Note |
|---|---|---|
| `nodeSelector` | Hard | Simple key-value match |
| Node Affinity (required) | Hard | Advanced expressions |
| Node Affinity (preferred) | Soft | Weight-based scoring |
| [[Taints]] + Tolerations | Hard | Node-level repulsion |
| Resource requests | Hard | Must fit on Node |
| PodAffinity | Soft/Hard | Co-location with other Pods |

## Manual Scheduling (Bypass Scheduler)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeName: worker-1   # Scheduler bypassed entirely
  containers:
  - name: nginx
    image: nginx
```

## Deployment

Runs as a [[Static Pods|Static Pod]]:

```bash
/etc/kubernetes/manifests/kube-scheduler.yaml
```

Key flags:
- `--leader-elect=true` — HA mode
- `--config=/etc/kubernetes/scheduler.conf`
- `--secure-port=10259`

## Key Commands

```bash
# Check scheduler pod
kubectl get pod kube-scheduler-<node> -n kube-system

# View scheduler logs
kubectl logs kube-scheduler-<node> -n kube-system

# Describe pod to see scheduling failure
kubectl describe pod <pod-name>
# Look for: Events → FailedScheduling

# Check pending pods
kubectl get pods --field-selector=status.phase=Pending
```

## Common Issues / Troubleshooting

- **Pod stuck in Pending** → scheduling failure; run `kubectl describe pod` and look for `FailedScheduling` event
- **No nodes match** → check resource requests vs Node capacity, nodeSelector labels, taint tolerations
- **Scheduler not running** → check static Pod manifest and kubelet logs
- **Multiple schedulers** → verify `schedulerName` in PodSpec

## Related Notes

- [[Scheduling]] — Full scheduling deep dive
- [[Node Affinity]] — Advanced node selection rules
- [[Taints]] — Node-level scheduling repulsion
- [[kube-apiserver]] — Scheduler communicates exclusively through it
- [[kubelet]] — Picks up Pod after scheduler binds it
- [[Cluster Architecture]] — Where scheduler fits

## Key Mental Model

The kube-scheduler is a **matchmaker**, not a manager. It finds the best Node for each Pod, makes the introduction, and steps away. Once the Pod is bound, the scheduler's job is done — [[kubelet]] takes over.
