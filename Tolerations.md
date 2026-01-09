# Tolerations
## Overview

A **toleration** is applied to a **Pod** and allows it to **ignore a matching Node taint**.
[[Taints]] repel Pods.
Tolerations grant permission.

A toleration **does not guarantee scheduling** — it only removes a barrier.

## Toleration Structure

```bash
tolerations:
- key: "dedicated"
  operator: "Equal"
  value: "infra"
  effect: "NoSchedule"
```

Fields:
- key
- operator
- value
- effect

## Operators

- Equal (default)
- Exists (value is ignored)

Example:

```bash
- key: "dedicated"
  operator: "Exists"
  effect: "NoSchedule"
```

Matches any taint with key dedicated.

## Effect Matching

A toleration must match the taint’s **effect**:
- NoSchedule
- PreferNoSchedule
- NoExecute

Mismatch = ignored.

## NoExecute Tolerations

Controls eviction behavior.

```yaml
- key: "maintenance"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
  tolerationSeconds: 300
```

Meaning:
- Pod can run on tainted node
- Evicted after 300 seconds

Without tolerationSeconds → stays forever.

## Default Tolerations

All Pods automatically tolerate:

```yaml
node.kubernetes.io/not-ready
node.kubernetes.io/unreachable
```

For a short time to prevent mass eviction.

## Tolerations Without Taints

Safe but useless.
A toleration alone does **nothing** unless a matching taint exists.

## Example: Dedicated Node Workload
### Taint the node

```bash
kubectl taint nodes node1 dedicated=infra:NoSchedule
```

### Pod toleration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: infra-pod
spec:
  tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "infra"
    effect: "NoSchedule"
  containers:
  - name: nginx
    image: nginx
```

## Common Mistakes

- Missing effect field
- Using Equal without value
- Expecting toleration to attract Pods
- Confusing tolerations with node affinity

## Tolerations vs Node Affinity

|**Feature**|**Tolerations**|**Node Affinity**|
|---|---|---|
|Removes restriction|Yes|No|
|Attracts Pods|No|Yes|
|Applied to|Pod|Pod|
|Works with taints|Yes|No|

Best practice:
> **Taints + Tolerations** to restrict
> **Affinity** to choose

## Debugging

```bash
kubectl describe pod <pod-name>
```

Look for:

```
node(s) had taint ... that the pod didn't tolerate
```

## Key Mental Model

Tolerations are:
- Permissions, not preferences
- Passive, not active
- Necessary but insufficient

A Pod with a toleration may enter.
A Pod with affinity chooses where to go.