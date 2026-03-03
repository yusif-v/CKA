---
tags: [cka/architecture, architecture, cli]
aliases: [Kubernetes API, API versioning, apiGroups]
---

# API Groups

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[RBAC]], [[kubectl]], [[Custom Resource Definition]]

## Overview

**API Groups** in Kubernetes are logical groupings of REST API endpoints that allow versioning, resource organization, and API extension. They prevent the core API from bloating and allow independent evolution of different resource families. Understanding API groups is essential for writing [[RBAC]] rules correctly.

## Two Types of API Groups

### Core Group (legacy)

- No group prefix in apiVersion → just `v1`
- Contains essential resources

```yaml
apiVersion: v1
```

Resources: [[Pods]], [[Services]], [[ConfigMap]]s, [[Secrets]], [[Namespaces]], Nodes, PersistentVolumes, PersistentVolumeClaims

### Named Groups

- Group prefix: `<group>/<version>`

```yaml
apiVersion: apps/v1
apiVersion: batch/v1
apiVersion: rbac.authorization.k8s.io/v1
```

## Common API Groups Reference

| API Group | apiVersion | Resources |
|---|---|---|
| core | `v1` | Pods, Services, ConfigMaps, Secrets, Nodes |
| apps | `apps/v1` | Deployments, StatefulSets, DaemonSets, ReplicaSets |
| batch | `batch/v1` | Jobs, CronJobs |
| rbac | `rbac.authorization.k8s.io/v1` | Roles, ClusterRoles, RoleBindings |
| networking | `networking.k8s.io/v1` | NetworkPolicies, Ingress |
| storage | `storage.k8s.io/v1` | StorageClasses |
| autoscaling | `autoscaling/v2` | HorizontalPodAutoscalers |
| CRD base | `apiextensions.k8s.io/v1` | CustomResourceDefinitions |

## API Versioning

| Stage | Meaning |
|---|---|
| `v1` | Stable, fully supported |
| `v1beta1` | Beta, may change |
| `v1alpha1` | Alpha, likely to change |

Deprecated versions are eventually removed. Use `kubectl api-versions` to see what's available.

## Key Commands

```bash
# List all API versions
kubectl api-versions

# List all resources with their API groups
kubectl api-resources

# Filter by group
kubectl api-resources --api-group=apps

# Check versions for a resource
kubectl explain deployment --api-version=apps/v1

# Check what API group a resource belongs to
kubectl api-resources | grep deployment
```

## API Groups in RBAC Rules

When writing [[RBAC]] roles, core group uses `""` (empty string):

```yaml
rules:
- apiGroups: [""]           # Core group (pods, services, etc.)
  resources: ["pods"]
  verbs: ["get", "list"]

- apiGroups: ["apps"]       # Named group
  resources: ["deployments"]
  verbs: ["get", "list", "create"]
```

## Custom Resources

[[Custom Resource Definition]]s create entirely new API groups:

```yaml
group: myapp.example.com
# Creates: myapp.example.com/v1
```

## Common Issues / Troubleshooting

- **"no matches for kind X"** → wrong apiVersion; check `kubectl api-resources`
- **RBAC not working** → wrong `apiGroups` in Role spec; use `""` for core group
- **Deprecated API warning** → migrate to newer version

## Related Notes

- [[kube-apiserver]] — Serves all API group endpoints
- [[RBAC]] — Uses apiGroups in rule definitions
- [[Custom Resource Definition]] — Creates new API groups
- [[kubectl]] — `kubectl api-resources` reveals available groups

## Key Mental Model

API Groups are like **departments in a company**: Core = HR & Admin (everything essential), Apps = Engineering & Projects, Batch = Operations. Each department has its own versioning rules, so clients can interact safely without stepping on each other's toes.
