---
tags: [cka/workloads, workloads]
aliases: [Taint, Toleration, Node Taint]
---

# Taints

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Scheduling]], [[Node Affinity]], [[Labels]], [[DaemonSets]], [[kube-scheduler]]

## Overview

A **taint** is applied to a **Node** to repel [[Pods]] — unless those Pods have a matching **toleration**. Taints work in reverse of [[Node Affinity|node affinity]]: instead of Pods being attracted to Nodes, Nodes push away Pods they don't want.

A **toleration** is added to a Pod spec to allow it to be scheduled onto a tainted Node.

## Taint Structure

```
key=value:effect
```

Examples:
- `dedicated=infra:NoSchedule`
- `node-role.kubernetes.io/control-plane:NoSchedule`
- `special:NoExecute`

## Taint Effects

| Effect | Behavior |
|---|---|
| `NoSchedule` | New Pods without toleration will NOT be scheduled |
| `PreferNoSchedule` | Scheduler avoids node if possible, but not strictly |
| `NoExecute` | New Pods blocked AND existing Pods without toleration are **evicted** |

## Key Commands

```bash
# Add a taint
kubectl taint nodes node1 dedicated=infra:NoSchedule

# Remove a taint (trailing dash)
kubectl taint nodes node1 dedicated=infra:NoSchedule-

# View node taints
kubectl describe node node1 | grep Taint

# View all nodes and their taints
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints
```

## Adding a Toleration to a Pod

```yaml
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "infra"
    effect: "NoSchedule"
```

Tolerate by key only (any value):

```yaml
tolerations:
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"
```

Tolerate all taints ([[DaemonSets]] pattern):

```yaml
tolerations:
- operator: Exists
```

## Default Taints

Control-plane nodes automatically have:

```
node-role.kubernetes.io/control-plane:NoSchedule
```

This prevents regular workloads from landing on control-plane nodes.

## NoExecute with tolerationSeconds

Pod will be evicted after `tolerationSeconds` if NoExecute taint is added:

```yaml
tolerations:
- key: "node.kubernetes.io/unreachable"
  operator: "Exists"
  effect: "NoExecute"
  tolerationSeconds: 300   # Evict after 5 minutes
```

Kubernetes automatically adds these tolerations to Pods to handle Node failures.

## Taints vs Node Affinity

| Feature | Taints | Node Affinity |
|---|---|---|
| Applied to | Node | Pod |
| Direction | Node repels Pod | Pod attracted to Node |
| Default behavior | Exclusive (opt-in) | Any node (opt-out) |
| Use case | Dedicated nodes | Preferred placement |

## Common Use Cases

- Dedicated GPU/SSD/infra nodes
- Protecting control-plane nodes
- Marking spot/preemptible nodes
- Isolating critical workloads
- Marking degraded/draining nodes

## Common Issues / Troubleshooting

- **Pod stuck Pending with taint message** → `kubectl describe pod` shows `node(s) had taint ... that the pod didn't tolerate`
- **Forgot to add toleration** → [[DaemonSets]] need `operator: Exists` to run on all nodes
- **NoExecute evicting running pods** → expected behavior; add toleration to prevent eviction
- **Can't remove taint** → syntax must match exactly including effect; use `kubectl describe node` to confirm taint string

## Related Notes

- [[Scheduling]] — Full scheduling context
- [[Node Affinity]] — Complementary attraction-based mechanism
- [[DaemonSets]] — Often need tolerations to run on all nodes
- [[OS Upgrade]] — Drain adds `NoExecute` taint temporarily
- [[kube-scheduler]] — Evaluates taints during filtering phase

## Key Mental Model

Taints are **defensive** — the node says "stay away unless you explicitly want to be here." Tolerations are the **key** that unlocks access. This makes nodes **opt-in** rather than opt-out, perfect for dedicated or special-purpose infrastructure.
