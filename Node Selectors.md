# Node Selectors

## Overview

**Node Selectors** are the **simplest way to constrain Pods to Nodes**.
They work by matching **node labels**.

If the label doesn’t match, the Pod will **never schedule**.
Think of nodeSelector as:

> “Only run this Pod on nodes with _these exact labels_.”

## How Node Selectors Work

- Applied to **Pods**
- Match against **Node labels**
- Enforced by [[kube-scheduler]]
- Hard requirement (no fallback)

```bash
Pod → nodeSelector → Node labels
```

## Labeling a Node

```bash
kubectl label node worker-1 disktype=ssd
```

Verify:

```bash
kubectl get nodes --show-labels
```

## Using nodeSelector in a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  nodeSelector:
    disktype: ssd
  containers:
  - name: nginx
    image: nginx
```

If no node has disktype=ssd → Pod stays Pending.

## nodeSelector Characteristics

- Equality-based only
- No operators (In, NotIn)
- No preferences
- Cannot express OR logic

Simple, blunt, effective.

## nodeSelector vs Node Affinity

| **Feature** | **nodeSelector** | **Node Affinity** |
| ----------- | ---------------- | ----------------- |
| Complexity  | Simple           | Advanced          |
| Operators   | No               | Yes               |
| Soft rules  | No               | Yes               |
| Expressive  | Low              | High              |
| Recommended | Legacy           | Preferred         |

Node Affinity **supersedes** nodeSelector.

## Combining with Taints & Tolerations

Common pattern:
- **Taint node** to repel everyone
- **Tolerate Pod** to allow entry
- **nodeSelector** to force placement

This gives both **exclusion and precision**.

## Common Use Cases

- SSD-only workloads
- GPU nodes
- Region / zone constraints
- Dedicated worker pools

## Debugging nodeSelector Issues

```bash
kubectl describe pod <pod-name>
```

Look for:

```
0/3 nodes are available: 3 node(s) didn't match Pod's node selector
```

## Key Mental Model

nodeSelector is:
- A lock, not a suggestion
- Exact match or nothing
- The “training wheels” of node placement

Once you need logic, preferences, or flexibility, you graduate to **Node Affinity**.