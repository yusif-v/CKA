---
tags: [cka/architecture, security]
aliases: [CRD, Custom Resource, Operator, API Extension]
---

# Custom Resource Definition

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[etcd]], [[RBAC]], [[API Groups]], [[kubectl]]

## Overview

A **Custom Resource Definition (CRD)** extends the Kubernetes API with **user-defined resource types**. Once created, Kubernetes treats your custom resource like any built-in resource — stored in [[etcd]], accessible via [[kubectl]], and manageable with [[RBAC]]. CRDs are the foundation for building **Operators** and platform automation.

## How CRDs Work

```
1. You define a CRD (schema + API group)
2. kube-apiserver creates new REST endpoints
3. Objects of the new type are stored in etcd
4. A controller/operator watches and reconciles
5. Users manage the resource like any built-in type
```

CRD = Schema + API Extension
Controller = Logic that makes it functional

## Creating a CRD

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: apps.platform.example.com   # Must be <plural>.<group>
spec:
  group: platform.example.com
  names:
    kind: App
    plural: apps
    singular: app
    shortNames:
    - ap
  scope: Namespaced   # Or: Cluster
  versions:
  - name: v1
    served: true      # Accessible via API
    storage: true     # Version used for persistence
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              image:
                type: string
              replicas:
                type: integer
                minimum: 1
```

## Creating a Custom Resource (Instance)

Once the CRD exists:

```yaml
apiVersion: platform.example.com/v1
kind: App
metadata:
  name: my-nginx
  namespace: dev
spec:
  image: nginx:1.25
  replicas: 3
```

This is stored in [[etcd]] and accessible via the API.

## CRD vs Built-in Resource

| Feature | Built-in Resource | CRD |
|---|---|---|
| Defined by | Kubernetes | User |
| Requires controller | Built-in | Must implement separately |
| kubectl support | ✅ Auto | ✅ Auto (after CRD installed) |
| RBAC | ✅ Built-in | ✅ Must configure |
| Storage in etcd | ✅ | ✅ |

## Operators = CRD + Controller

An **Operator** is the pattern of pairing a CRD with a controller:

```
Custom Resource (desired state)
    ↓
Operator Controller (watches + reconciles)
    ↓
Actual cluster state
```

Examples: database operators (PostgreSQL, MySQL), cert-manager, ArgoCD.

## RBAC for CRDs

Custom resources need [[RBAC]] rules like any other resource:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-manager
  namespace: dev
rules:
- apiGroups: ["platform.example.com"]   # Your CRD's group
  resources: ["apps"]
  verbs: ["get", "list", "create", "update", "delete"]
```

## Key Commands

```bash
# List all CRDs
kubectl get crd

# Describe a CRD
kubectl describe crd apps.platform.example.com

# List resources of a custom type
kubectl get apps -n dev
kubectl get app my-nginx -n dev -o yaml

# Check API groups (CRD creates new endpoints)
kubectl api-resources | grep platform.example.com

# Explain custom resource fields
kubectl explain app.spec
```

## Common Issues / Troubleshooting

- **"no matches for kind"** → CRD not installed; `kubectl get crd | grep <name>`
- **Validation error on create** → field doesn't match `openAPIV3Schema`; check the schema
- **CRD deleted but objects remain** → objects become orphaned; always delete objects before CRD
- **RBAC 403 on custom resource** → add `apiGroups: ["<group>"]` to role rules

## Related Notes

- [[kube-apiserver]] — Hosts the new API endpoints created by CRDs
- [[API Groups]] — CRDs create new API groups (e.g., `platform.example.com/v1`)
- [[RBAC]] — Must explicitly grant permissions on custom resources
- [[etcd]] — Custom resource instances are stored here

## Key Mental Model

A CRD is a **new vocabulary word** taught to Kubernetes. Before: Kubernetes only knew Pods and Deployments. After: it also knows `App`, `Database`, `Certificate` — whatever you define. The CRD defines the word; the controller gives it **meaning and behavior**.
