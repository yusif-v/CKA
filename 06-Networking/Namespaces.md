---
tags: [cka/networking, networking, cka/architecture]
aliases: [Namespace, Kubernetes Namespace, ns]
---

# Namespaces

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[RBAC]], [[Network Policy]], [[ResourceQuota]], [[Services]], [[kubectl]]

## Overview

A **Namespace** is a logical partition inside a Kubernetes cluster that allows multiple teams, environments, or applications to share the same cluster **without name collisions**. Namespaces scope names, [[RBAC]] permissions, resource quotas, and [[Network Policy|network policies]] — but they are **not security boundaries by default**.

## Default Namespaces

| Namespace | Purpose |
|---|---|
| `default` | Resources go here if no namespace specified |
| `kube-system` | Control plane components |
| `kube-public` | Publicly readable data (rarely used) |
| `kube-node-lease` | Node heartbeat leases |

## Namespaced vs Cluster-Scoped Resources

**Namespaced** (scoped to a namespace):
- [[Pods]], [[Deployments]], [[DaemonSets]], [[Services]]
- [[ConfigMap]]s, [[Secrets]]
- Roles, RoleBindings

**Cluster-Scoped** (exist at cluster level):
- Nodes, PersistentVolumes, [[Storage Class]]
- [[Namespaces]] themselves
- ClusterRoles, ClusterRoleBindings

## Key Commands

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace dev

# Work in specific namespace
kubectl get pods -n dev
kubectl apply -f pod.yaml -n dev

# Set default namespace for current context (exam shortcut)
kubectl config set-context --current --namespace=dev

# Get all resources across all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Delete namespace (deletes all resources inside it)
kubectl delete namespace dev
```

## Namespace Definition File

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    team: backend    # Label namespaces for NetworkPolicy rules
```

## Resource Quotas

Limit resources per namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "20"
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    secrets: "10"
    services: "10"
```

## DNS Across Namespaces

Service DNS format: `<service>.<namespace>.svc.cluster.local`

- Same namespace: `http://backend` or `http://backend.dev`
- Cross-namespace: `http://backend.prod` or `http://backend.prod.svc.cluster.local`

## Namespace Isolation Notes

- Namespaces do **NOT** provide network isolation by default — use [[Network Policy]]
- Namespaces do **NOT** prevent privilege escalation — use [[RBAC]] and [[Security Contexts]]
- Namespaces are a **naming and organizational** boundary, not a security boundary

## Common Issues / Troubleshooting

- **Namespace stuck in Terminating** → finalizers preventing deletion; check `kubectl get ns dev -o yaml` for finalizers
- **"not found" when applying** → forgot `-n <namespace>` flag; resource went to `default`
- **Service not reachable cross-namespace** → use full DNS name `<svc>.<ns>.svc.cluster.local`
- **ResourceQuota blocking pod creation** → `kubectl describe resourcequota -n dev`

## Related Notes

- [[RBAC]] — Roles and RoleBindings are namespace-scoped
- [[Network Policy]] — Enforce cross-namespace traffic rules
- [[Services]] — DNS includes namespace in the FQDN
- [[ConfigMap]] and [[Secrets]] — Namespace-scoped; can't be shared across namespaces directly

## Key Mental Model

A Namespace is a **folder with rules** — not a wall. It provides organizational structure, resource quota enforcement, and RBAC scoping. For actual isolation, you need [[Network Policy]] (network) and [[RBAC]] (access control) layered on top.
