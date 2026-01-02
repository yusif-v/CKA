## **Overview**

A **Namespace** is a logical partition inside a Kubernetes cluster.

It allows multiple teams, environments, or applications to share the same cluster **without interfering** with each other.

Namespaces scope:
- Names of resources (Pods, Services, Deployments)
- RBAC permissions
- Resource quotas and limits
- Network policies

Some resources are **namespaced**, others are **cluster-wide**.

## Default Namespaces

Kubernetes ships with several built-in namespaces:
- default – resources go here if no namespace is specified
- kube-system – control plane components
- kube-public – publicly readable data (rarely used)
- kube-node-lease – node heartbeat leases

## Namespaced vs Cluster-Scoped Resources
### Namespaced

- Pod
- Service
- Deployment
- ConfigMap
- Secret
- Role / RoleBinding

### Cluster-Scoped

- Node
- Namespace
- PersistentVolume
- ClusterRole / ClusterRoleBinding
- CustomResourceDefinition

Rule of thumb:
If it describes **workloads**, it’s namespaced.
If it describes **the cluster itself**, it isn’t.

## Creating a Namespace
### Using kubectl

```
kubectl create namespace dev
```

### Using a definition file

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
```

```bash
kubectl apply -f namespace.yaml
```

## Working with Namespaces
### List namespaces

```bash
kubectl get namespaces
```

### Create resources in a namespace

```bash
kubectl apply -f pod.yaml -n dev
```

### View resources in a namespace

```bash
kubectl get pods -n dev
```

### View resources across all namespaces

```bash
kubectl get pods --all-namespaces
```

## Setting a Default Namespace (kubectl context)

```bash
kubectl config set-context --current --namespace=dev
```

Verify:

```bash
kubectl config view --minify
```

This saves a lot of typing during exams and real life.

## Resource Quotas

Namespaces enable resource limits **per team or environment**.

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    pods: "10"
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "6"
    limits.memory: 12Gi
```

## Namespace Deletion Behavior

When a namespace is deleted:

- All namespaced resources are deleted
- Finalizers may delay deletion
- Cluster-scoped resources are untouched

Common issue:

```
kubectl get namespace dev -o yaml
```

Look for finalizers if stuck in Terminating.

## Networking and Namespaces

- Namespaces **do NOT provide isolation by default**
- Pods can communicate across namespaces
- Use **NetworkPolicies** for isolation

DNS format:

```
service-name.namespace.svc.cluster.local
```

## Key Mental Model

A Namespace is:
- Not a VM
- Not a security boundary by default
- A **scope**

Think of it as a **folder with rules**, not a wall.
