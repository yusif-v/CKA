# Network Policy
## Overview

A **Network Policy** controls how Pods communicate with each other and with the outside world.
It is Kubernetes’ built-in way of defining **firewall rules at the Pod level**.

By default, Kubernetes networking is **wide open** — every Pod can talk to every other Pod.
Network Policies let you move from that “flat universe” to **explicitly allowed traffic**.

Network Policy is implemented by the cluster’s CNI plugin and is part of the security model promoted by [Kubernetes](chatgpt://generic-entity?number=0) under the umbrella of the [Cloud Native Computing Foundation](chatgpt://generic-entity?number=1).

## Important Requirement

Network Policies only work if your **CNI plugin supports them**.

Supported examples:
- Calico
- Cilium
- Weave Net (partial)

If the CNI does not support policies → the YAML will apply but do nothing.

## What Network Policy Controls

You can restrict:
- **Ingress** → traffic coming into Pods
- **Egress** → traffic leaving Pods

Policies are **allow rules**, not deny rules.

If a Pod is selected by a policy, anything not explicitly allowed is blocked.

## Basic Mental Model

Without NetworkPolicy:

```bash
All Pods ↔ All Pods (Allowed)
```

With NetworkPolicy:

```bash
Only explicitly permitted traffic is allowed.
Everything else is dropped.
```

This is called a **default-deny model**.

## Example: Allow Traffic Only from Frontend to Backend

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: default
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
```

### What This Does

- Selects Pods labeled app=backend
- Allows traffic **only** from Pods labeled app=frontend
- Blocks everything else

## Default Deny Example

To isolate a namespace completely:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Now **no Pod can receive traffic** unless another policy allows it.

## Allow Specific Port

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-http
spec:
  podSelector:
    matchLabels:
      app: web
  ingress:
  - ports:
    - protocol: TCP
      port: 80
```

Only TCP/80 is allowed.

## Egress Control Example

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: restrict-egress
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: db
```

This prevents the API Pod from talking to anything except the database Pods.

## Combining Rules

Network Policies are **additive**.

If multiple policies apply:
→ Allowed traffic is the union of all allowed rules.

There is no rule ordering. No first-match logic.
This is not iptables thinking — it’s declarative math.

## Namespace-Based Access

Allow traffic from another namespace:

```yaml
from:
- namespaceSelector:
    matchLabels:
      team: dev
```

Namespace labels become part of your security model.

## Debugging Network Policies

Check policies:

```bash
kubectl get networkpolicy
```

Describe:

```bash
kubectl describe networkpolicy allow-frontend
```

Test connectivity from a Pod:

```bash
kubectl exec -it test-pod -- curl backend
```

If it fails → policy is doing its job.

## Common Pitfalls

- Forgetting that policies require **CNI support**
- Applying policy but not selecting Pods correctly
- Missing DNS egress rules (Pods suddenly cannot resolve names)
- Assuming deny rules exist (they don’t)

## Best Practices

- Start with **default deny**
- Open only required ports and sources
- Label namespaces intentionally
- Always allow DNS (UDP/53) when using egress policies
- Treat policies like application-layer firewall rules

## Key Mental Model

NetworkPolicy is Kubernetes saying:

> “Pods are not cattle wandering an open field.
> They are services in a zero-trust datacenter.”

You must **declare who is allowed to speak to whom**.

In other words, NetworkPolicy turns the cluster from a noisy party into a carefully moderated scientific conference where only the right conversations are allowed to happen.