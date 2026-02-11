# API Groups
## Overview

**API Groups** in Kubernetes are **logical groupings of REST API endpoints** that allow for:
- Versioning
- Organizing resources
- Extending Kubernetes with new APIs

They prevent the **core API** from becoming too large and allow evolution without breaking clients.

## Core Concepts

- **Core Group** → v1 (no group prefix)
    Examples: Pods, Services, ConfigMaps, Nodes
- **Named Groups** → apps/v1, batch/v1, rbac.authorization.k8s.io/v1
    Examples: Deployments, StatefulSets, Jobs, Roles

## Examples of API Groups

|**API Group**|**Resources**|
|---|---|
|core (v1)|Pods, Services, ConfigMaps, Secrets, Nodes|
|apps/v1|Deployments, StatefulSets, DaemonSets, ReplicaSets|
|batch/v1|Jobs, CronJobs|
|rbac.authorization.k8s.io/v1|Roles, ClusterRoles, RoleBindings|
|networking.k8s.io/v1|NetworkPolicies, Ingress|

## Checking Available API Groups

```bash
kubectl api-versions
```

Check resources in a group:

```bash
kubectl api-resources --api-group=apps
```

## Resource Access Example
### Pods (Core API)

```bash
kubectl get pods
```
### Deployments (apps/v1)

```bash
kubectl get deployments
```
## Versioning

Each API group may have multiple versions:
- v1, v1beta1, v2alpha1
- Allows **backward compatibility**
- Deprecated versions are eventually removed

Check versions of a resource:

```bash
kubectl explain deployment --api-version=apps/v1
```

## Custom Resource Definitions (CRDs)

- Extend Kubernetes with **new API Groups**
- Example: mygroup.example.com/v1alpha1
- CRDs create **new REST endpoints**

🔗 Related:
- [[Custom Resource Definitions]]

## Key Mental Model

API Groups are like **departments in a company**:
- Core = HR & Admin (everything essential)
- Apps = Engineering & Projects
- Batch = Operations & Schedulers
- RBAC = Security

Each group has **its own versioning rules**, so clients can interact safely without stepping on other departments’ toes.