---
tags: [cka/architecture, security]
aliases: [RBAC, Role-Based Access Control, Role, ClusterRole, RoleBinding]
---

# RBAC

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Kubeconfig]], [[Secrets]], [[Namespaces]], [[kube-apiserver]], [[ServiceAccounts]]

## Overview

**RBAC (Role-Based Access Control)** is Kubernetes' default authorization mechanism. It controls what authenticated users, groups, or service accounts can do within the cluster. Authorization answers: **"Is this identity allowed to perform this action on this resource?"**

> [!tip] Exam Tip
> `kubectl auth can-i` is essential for testing RBAC. Know it cold: `kubectl auth can-i create pods --as alice -n dev`

## Core Concepts

RBAC has four objects:

| Object | Scope | Purpose |
|---|---|---|
| `Role` | Namespace | Grants permissions inside one namespace |
| `ClusterRole` | Cluster-wide | Grants permissions across all namespaces or on cluster-scoped resources |
| `RoleBinding` | Namespace | Binds a Role (or ClusterRole) to subjects in a namespace |
| `ClusterRoleBinding` | Cluster-wide | Binds a ClusterRole to subjects across the whole cluster |

## Role (Namespaced)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: dev
rules:
- apiGroups: [""]           # "" = core API group (pods, services, etc.)
  resources: ["pods", "pods/log"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "create", "update", "patch"]
```

## ClusterRole (Cluster-wide)

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
- apiGroups: [""]
  resources: ["nodes", "persistentvolumes"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list"]
```

## RoleBinding

Binds a Role or ClusterRole to users/groups/serviceaccounts **within a namespace**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: alice-pod-reader
  namespace: dev
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
- kind: ServiceAccount
  name: my-serviceaccount
  namespace: dev
roleRef:
  kind: Role           # Can also be ClusterRole
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

## ClusterRoleBinding

Binds a ClusterRole to subjects **cluster-wide**:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: alice-node-reader
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: node-reader
  apiGroup: rbac.authorization.k8s.io
```

## Common Verbs

| Verb | Action |
|---|---|
| `get` | Read a specific resource |
| `list` | List resources |
| `watch` | Watch for changes |
| `create` | Create resource |
| `update` | Full update |
| `patch` | Partial update |
| `delete` | Delete resource |
| `*` | All verbs |

## Imperative RBAC Commands

```bash
# Create Role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n dev

# Create RoleBinding
kubectl create rolebinding alice-pod-reader \
  --role=pod-reader \
  --user=alice \
  -n dev

# Create ClusterRole
kubectl create clusterrole node-reader \
  --verb=get,list,watch \
  --resource=nodes,persistentvolumes

# Create ClusterRoleBinding
kubectl create clusterrolebinding alice-node-reader \
  --clusterrole=node-reader \
  --user=alice
```

## Key Commands

```bash
# Test permissions (exam essential)
kubectl auth can-i create pods
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'   # Check admin
kubectl auth can-i list secrets --as system:serviceaccount:dev:my-sa

# List RBAC objects
kubectl get roles -n dev
kubectl get rolebindings -n dev
kubectl get clusterroles
kubectl get clusterrolebindings

# Describe role (shows rules)
kubectl describe role pod-reader -n dev

# Describe binding (shows subjects + role)
kubectl describe rolebinding alice-pod-reader -n dev
```

## Common Issues / Troubleshooting

- **403 Forbidden** → subject lacks permission; test with `kubectl auth can-i`, then add to Role
- **ClusterRoleBinding instead of RoleBinding** → accidentally gave cluster-wide access; scope to namespace with RoleBinding
- **Wrong `apiGroups`** → core resources need `""` not `"core"`; apps resources need `"apps"`
- **ServiceAccount not found** → check namespace; SA must exist before binding
- **Permission exists but still denied** → may be blocked by admission controller or NetworkPolicy

## Related Notes

- [[Kubeconfig]] — Identity used in RBAC is the user/SA from kubeconfig
- [[Secrets]] — RBAC restricts who can read Secrets
- [[Namespaces]] — Roles and RoleBindings are namespace-scoped
- [[kube-apiserver]] — RBAC is enforced at the API server authorization layer
- [[TLS in Kubernetes]] — User identity from client certificates feeds into RBAC

## Key Mental Model

RBAC is **"who can do what where?"**: Role = job description. RoleBinding = assignment in a department (namespace). ClusterRole = company-wide role. ClusterRoleBinding = company-wide assignment. Permissions are **granted explicitly** — if it's not listed, it's denied.
