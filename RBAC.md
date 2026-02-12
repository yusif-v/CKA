# RBAC (Role-Based Access Control)
## Overview

**RBAC** is Kubernetes’ default **authorization mechanism**.
It **controls what authenticated users or service accounts can do** within the cluster.

Authorization answers the question:
**“Is this identity allowed to perform this action on this resource?”**

🔗 Related:
- [[Authentication]]
- [[Kubeconfig]]

## Core Concepts
### 1. Role

- Defines **permissions within a namespace**
- Specifies allowed **verbs** (get, list, create, delete) on **resources**
- YAML example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: dev
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

### 2. ClusterRole

- Similar to Role but **cluster-wide**
- Can grant access to namespaced or non-namespaced resources
- Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### 3. RoleBinding

- Assigns a **Role to a user, group, or service account** in a namespace
- Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods-binding
  namespace: dev
subjects:
- kind: User
  name: alice
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

### 4. ClusterRoleBinding

- Assigns a **ClusterRole to a user, group, or service account cluster-wide**
- Example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: cluster-admin-binding
subjects:
- kind: User
  name: admin
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
```

## RBAC Resources Summary

|**Resource**|**Scope**|**Purpose**|
|---|---|---|
|Role|Namespaced|Grants permissions inside a namespace|
|ClusterRole|Cluster-wide|Grants permissions across cluster|
|RoleBinding|Namespaced|Binds a Role to users/SA in a namespace|
|ClusterRoleBinding|Cluster-wide|Binds a ClusterRole to users/SA across cluster|

## Viewing RBAC Objects

```bash
kubectl get roles -n dev
kubectl get rolebindings -n dev
kubectl get clusterroles
kubectl get clusterrolebindings
```

Check access:

```bash
kubectl auth can-i create pods --as alice -n dev
```

## Best Practices

- Follow **least privilege** principle
- Use **ClusterRole only when needed**
- Prefer **RoleBindings** in namespaces
- Regularly review bindings
- Use **service accounts** for automated workloads

## Common Pitfalls

- Assigning cluster-admin unnecessarily
- Forgetting namespace in RoleBinding
- Confusing Role vs ClusterRole
- Overlapping bindings causing unexpected permissions

## Key Mental Model

RBAC is **“who can do what where?”** in Kubernetes:
- Role = job description
- RoleBinding = assignment in a department (namespace)
- ClusterRole = company-wide role
- ClusterRoleBinding = company-wide assignment

Permissions are **granted explicitly**; nothing is assumed.