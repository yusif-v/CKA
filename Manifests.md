# Manifests
## **Overview**

A **manifest** is a **YAML (or JSON) file** that declaratively describes a Kubernetes object.

Manifests are the **source of truth** for cluster state.

You don’t tell Kubernetes _how_ to do things — you tell it _what the desired state is_.

## What a Manifest Contains

Every Kubernetes manifest follows the same structural logic:
- **apiVersion** – which API group/version to use
- **kind** – what type of object this is
- **metadata** – identity and labels
- **spec** – desired state
- **status** – actual state (managed by Kubernetes)

Only **spec** is user-defined.

**status** is read-only.

## Basic Manifest Structure

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
  labels:
    app: demo
spec:
  containers:
  - name: nginx
    image: nginx
```

This file is a **declaration**, not a command.

## Declarative Model

Manifests work on the **declarative principle**:
- You declare the desired state
- Kubernetes continuously reconciles reality to match it

Controllers compare:
- Desired state (manifest)
- Actual state (cluster)

Then they act.

## Applying Manifests

Create or update resources:

```bash
kubectl apply -f manifest.yaml
```

Delete resources:

```bash
kubectl delete -f manifest.yaml
```

Preview changes:

```bash
kubectl diff -f manifest.yaml
```

## Manifest Types

Manifests can define any Kubernetes object:
- [[Pods]]
- [[ReplicaSet]]
- [[Deployments]]
- [[DaemonSets]]
- [[Services]]
- [[ConfigMap]]
- [[Secret]]
- [[Namespaces]]

One file can define **one or multiple objects**.

## Multi-Object Manifests

Multiple resources in one file are separated by ---:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: demo
spec:
  containers:
  - name: nginx
    image: nginx
```

## Static Pod Manifests

Static Pods are also defined using manifests, but:
- Stored on Node filesystem
- Read directly by [[kubelet]]
- Not created via API

See: [[Static Pods]]

## Imperative vs Declarative

Imperative:

```
kubectl run nginx --image=nginx
```

Declarative:

```
kubectl apply -f nginx.yaml
```

Manifests are **always preferred** for:

- Version control
- Reproducibility
- GitOps workflows

## Validation and Schema

When you apply a manifest:
1. [[kube-apiserver]] validates it
2. Admission controllers mutate/validate
3. Object is persisted in etcd

Invalid fields are rejected early.

## Best Practices

- One resource per file (cleaner diffs)
- Use labels consistently
- Store manifests in Git
- Avoid editing live objects with kubectl edit long-term

## Key Mental Model

A manifest is a **contract with the cluster**.
You state what _must be true_.
Kubernetes spends all its energy making sure reality obeys the document.