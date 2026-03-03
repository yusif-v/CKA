---
tags: [cka/networking, networking]
aliases: [NetworkPolicy, Pod Firewall, Network Isolation]
---

# Network Policy

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Services]], [[Namespaces]], [[Labels]], [[Pods]], [[Ingress]]

## Overview

A **Network Policy** is a Kubernetes resource that controls **which Pods can communicate with which other Pods** (and external endpoints). By default, all Pods can communicate with all other Pods — Network Policies implement a **firewall-like model** at the Pod level.

> [!important]
> Network Policies only work if a **CNI plugin that supports NetworkPolicy** is installed (e.g., Calico, Cilium, Weave). Flannel does NOT support Network Policies.

## Default Behavior

- **No NetworkPolicy** → all traffic allowed (open by default)
- **NetworkPolicy selects a Pod** → all traffic to/from that Pod is **denied by default**; only explicitly allowed traffic passes
- Multiple policies are **additive** (union of allowed traffic)

## Policy Structure

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: app
spec:
  podSelector:           # Which pods this policy applies to
    matchLabels:
      role: backend

  policyTypes:
  - Ingress              # Control incoming traffic
  - Egress               # Control outgoing traffic

  ingress:               # Allow incoming from:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080

  egress:                # Allow outgoing to:
  - to:
    - podSelector:
        matchLabels:
          role: database
    ports:
    - protocol: TCP
      port: 5432
```

## Default Deny All Policy

Isolate all Pods in a namespace — deny all traffic:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: app
spec:
  podSelector: {}    # Selects ALL pods in namespace
  policyTypes:
  - Ingress
  - Egress
```

## Allow Ingress from Specific Namespace

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        team: frontend
```

## Combining Pod and Namespace Selectors

When using both in the same `from` entry, both must match (AND):

```yaml
ingress:
- from:
  - namespaceSelector:
      matchLabels:
        env: prod
    podSelector:          # Same list item = AND
      matchLabels:
        role: api
```

Separate list items = OR:

```yaml
ingress:
- from:
  - namespaceSelector:    # Different list items = OR
      matchLabels:
        env: prod
  - podSelector:
      matchLabels:
        role: api
```

## Allow DNS Egress (Critical!)

If you apply an egress policy, always allow DNS or Pods can't resolve names:

```yaml
egress:
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
  ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
```

## Key Commands

```bash
# List Network Policies
kubectl get networkpolicy
kubectl get networkpolicy -n app

# Describe a policy
kubectl describe networkpolicy allow-frontend -n app

# Test connectivity from a pod (requires running pod)
kubectl exec -it test-pod -n app -- curl backend:8080

# Test with a temporary pod
kubectl run test --image=busybox --rm -it -- wget -qO- http://backend:8080
```

## Common Issues / Troubleshooting

- **CNI doesn't support NetworkPolicy** → policies exist but have no effect; switch to Calico/Cilium
- **Forgetting DNS egress** → Pods can't resolve hostnames after applying egress policy
- **AND vs OR confusion** → same `from` list item = AND, different list items = OR
- **Empty podSelector** → selects ALL pods (intentional for default-deny)
- **Wrong namespace** → NetworkPolicy is namespace-scoped; check with `-n`

## Related Notes

- [[Services]] — Network Policy controls traffic to/from Services' backend Pods
- [[Namespaces]] — Policies are namespaced; label namespaces for cross-namespace rules
- [[Labels]] — Selectors in NetworkPolicy use pod/namespace labels
- [[Ingress]] — Network Policy operates at L3/L4; Ingress at L7

## Key Mental Model

NetworkPolicy turns Kubernetes from a **noisy open party** into a **carefully moderated conference** — only the right conversations are allowed. By default, no one is blocked. Once you add a policy, everything not explicitly allowed is denied. Start with **default deny**, then open only what's needed.
