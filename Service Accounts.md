# Service Accounts
## Overview

A **Service Account (SA)** provides an **identity for processes running inside Pods**.

It allows Pods to:
- Authenticate to the Kubernetes API
- Interact with cluster resources securely
- Be governed by [[RBAC]] permissions

Without Service Accounts, every container would be an anonymous stranger trying to press buttons in the control room.

## Default Behavior

Every namespace automatically has a **default Service Account**.

If you don’t specify one in a Pod:
→ Kubernetes assigns the default ServiceAccount.

Check it:

```bash
kubectl get sa
```

## How It Works Internally

When a Pod uses a Service Account:
1. Kubernetes creates a **token**
2. Token is mounted into the Pod at:

```bash
/var/run/secrets/kubernetes.io/serviceaccount
```

3. The Pod uses this token to talk to the API Server
4. API Server checks permissions using [[RBAC]]
  
So the chain is:

**Pod → ServiceAccount → Token → API Server → RBAC Authorization**

## Creating a Service Account

```bash
kubectl create serviceaccount app-sa
```

Verify:

```bash
kubectl get sa app-sa -o yaml
```

## Using Service Account in a Pod

```bash
apiVersion: v1
kind: Pod
metadata:
  name: sa-demo
spec:
  serviceAccountName: app-sa
  containers:
  - name: nginx
    image: nginx
```

Once deployed, this Pod now acts **as app-sa**, not as default.

## Granting Permissions with RBAC

Service Accounts by themselves do nothing.
They must be bound to Roles.

Example RoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sa-read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: default
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Now the Pod using app-sa can read Pods — but nothing else.

## Listing Service Account Tokens (K8s ≥1.24 Behavior)

Modern Kubernetes uses **projected tokens** instead of long-lived secrets.

Check mounted token inside a Pod:

```bash
kubectl exec -it sa-demo -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

You’ll see:
- token
- ca.crt
- namespace

These tokens are **short-lived and automatically rotated** — a major security improvement.

## Disabling Automatic Mount (Security Hardening)

If a Pod does NOT need API access:

```bash
spec:
  automountServiceAccountToken: false
```

This prevents unnecessary credential exposure.

## Cluster-Wide Usage Example

Controllers, CI/CD tools, GitOps agents, and operators all rely heavily on Service Accounts.

Examples:
- ArgoCD uses SA to deploy apps
- Prometheus uses SA to read metrics
- Operators manage CRDs using SA identity

These are machine users, not human users.

## Useful Commands

List Service Accounts:

```bash
kubectl get sa -A
```

Describe SA:

```bash
kubectl describe sa app-sa
```

Check what it can do:

```bash
kubectl auth can-i get pods --as system:serviceaccount:default:app-sa
```

## Key Mental Model

Humans authenticate with **certificates or kubeconfig**.
Pods authenticate with **Service Accounts**.

So:

**User Account = You logging into the cluster**
**Service Account = Workload identity inside the cluster**

Or put differently: Service Accounts are the Kubernetes equivalent of giving each robot its own badge instead of sharing the master key.