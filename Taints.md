# Taints
## Overview

A **taint** is applied to a **Node** and tells the scheduler:

> “Pods should NOT run here — unless they explicitly tolerate this.”

Taints work **in reverse** of [[Labels]]/[[Selectors]].
[[Labels]] attract Pods.
Taints repel Pods.

## Taint Structure

```bash
key=value:effect
```

Example:

```bash
dedicated=infra:NoSchedule
```

Parts:

- key
- value
- effect

## Taint Effects

- NoSchedule
    Pods without toleration will not be scheduled
    
- PreferNoSchedule
    Scheduler avoids the node if possible
    
- NoExecute
    Existing Pods without toleration are evicted

## Adding a Taint

```bash
kubectl taint nodes node1 dedicated=infra:NoSchedule
```

## Removing a Taint

```bash
kubectl taint nodes node1 dedicated=infra:NoSchedule-
```

Trailing - removes it.

## Viewing Node Taints

```bash
kubectl describe node node1
```

Look under **Taints**.

## Default Taints

Control plane nodes often have:

```yaml
node-role.kubernetes.io/control-plane:NoSchedule
```

This prevents workloads from running on control plane nodes unless tolerated.

## Taints Without Values

```bash
kubectl taint nodes node1 special:NoSchedule
```

Valid — toleration just matches the key.

## What Taints Do NOT Do

- Do not select Pods
- Do not guarantee exclusivity
- Do not replace RBAC or security

They only influence **scheduling and eviction**.

## Common Use Cases

- Dedicated nodes (infra, GPU, DB)
- Isolating critical workloads
- Protecting control plane
- Handling spot / preemptible nodes

## Debugging Scheduling with Taints

Pod stuck in Pending?

```bash
kubectl describe pod <pod-name>
```

Look for:

```
node(s) had taint {key=value:effect}, that the pod didn't tolerate
```

## Key Mental Model

Taints are:
- Node-centric
- Defensive
- Explicit barriers

A node with a taint is **opt-in**, not opt-out.