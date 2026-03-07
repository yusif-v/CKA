---
tags: [cka/architecture, security]
aliases: [ServiceAccount, SA, service account, default SA, automount]
---

# ServiceAccounts

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[RBAC]], [[Secrets]], [[Pods]], [[Namespaces]], [[kube-apiserver]], [[Image Security]]

## Overview

A **ServiceAccount** is a Kubernetes identity for **processes running inside Pods**. While human users authenticate via certificates or OIDC, workloads (Pods) authenticate to the Kubernetes API using a ServiceAccount token. Every Pod runs as exactly one ServiceAccount; if none is specified, it runs as the `default` ServiceAccount in its namespace.

## How It Works

```
Pod → mounts SA token → presents token to kube-apiserver → RBAC evaluates permissions
```

When a Pod is created, Kubernetes automatically:
1. Assigns the specified (or `default`) ServiceAccount
2. Mounts a token as a projected volume at `/var/run/secrets/kubernetes.io/serviceaccount/`
3. Also mounts the CA cert and namespace name at the same path

The token is a **short-lived, audience-bound JWT** (since Kubernetes 1.24). Older clusters used long-lived tokens stored in [[Secrets]].

## Default ServiceAccount

Every namespace gets a `default` ServiceAccount automatically. It has **no RBAC permissions** by default, but the token is still mounted — a risk if the app is compromised.

```bash
# Inspect the default SA in a namespace
kubectl get serviceaccount default -n dev -o yaml
```

## Creating a ServiceAccount

### Imperative

```bash
kubectl create serviceaccount my-sa -n dev
```

### Declarative

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: dev
```

## Assigning a ServiceAccount to a Pod

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-app
  namespace: dev
spec:
  serviceAccountName: my-sa   # Assign the SA here
  containers:
  - name: app
    image: myapp:1.0
```

> [!tip] Exam Tip
> `serviceAccountName` is set at the **Pod spec level**, not the container level. In a [[Deployments|Deployment]], set it under `spec.template.spec.serviceAccountName`.

## Disabling Token Automount

By default, the SA token is automounted. Disable it to reduce the attack surface for Pods that don't need API access:

### On the ServiceAccount (affects all Pods using it)

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-sa
  namespace: dev
automountServiceAccountToken: false
```

### On the Pod (overrides the SA setting)

```yaml
spec:
  automountServiceAccountToken: false
```

> [!warning]
> Setting `automountServiceAccountToken: false` on the `default` SA in a namespace is a security best practice — it prevents unintentional API access from all Pods that don't specify an SA.

## Binding Permissions with RBAC

A ServiceAccount alone has no permissions. Grant them via [[RBAC]] RoleBinding or ClusterRoleBinding:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: my-sa-pod-reader
  namespace: dev
subjects:
- kind: ServiceAccount
  name: my-sa
  namespace: dev
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

Test permissions for a ServiceAccount:

```bash
kubectl auth can-i list pods \
  --as system:serviceaccount:dev:my-sa \
  -n dev
```

> [!tip] Exam Tip
> The `--as` format for ServiceAccounts is always `system:serviceaccount:<namespace>:<sa-name>`. Know this cold.

## Token Types

| Type | Kubernetes Version | Storage | Expiry |
|---|---|---|---|
| Long-lived token | ≤ 1.23 | Stored in a [[Secrets\|Secret]] | Never expires |
| Projected token (bound) | ≥ 1.24 | Projected volume (no Secret) | Short-lived (~1 hour) |

Since 1.24, `kubectl create serviceaccount` no longer auto-creates a token Secret. To create a long-lived token manually (not recommended):

```bash
kubectl create token my-sa -n dev                  # Short-lived (default 1h)
kubectl create token my-sa -n dev --duration=8760h  # Long-lived (1 year)
```

Or via a Secret with the annotation:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-sa-token
  namespace: dev
  annotations:
    kubernetes.io/service-account.name: my-sa
type: kubernetes.io/service-account-token
```

## Attaching imagePullSecrets to a ServiceAccount

All Pods using the SA automatically get the pull secret — no need to add it to every Pod:

```bash
kubectl patch serviceaccount my-sa -n dev \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'
```

See [[Image Security]] for creating the `docker-registry` Secret.

## Key Commands

```bash
# Create a ServiceAccount
kubectl create serviceaccount my-sa -n dev

# List ServiceAccounts in a namespace
kubectl get serviceaccounts -n dev

# Describe SA (shows secrets/token references)
kubectl describe serviceaccount my-sa -n dev

# Generate a short-lived token (1 hour default)
kubectl create token my-sa -n dev

# Test permissions as a ServiceAccount
kubectl auth can-i list pods \
  --as system:serviceaccount:dev:my-sa -n dev

# Check what SA a running pod uses
kubectl get pod my-app -o jsonpath='{.spec.serviceAccountName}'

# View mounted token inside a pod
kubectl exec -it my-app -- cat /var/run/secrets/kubernetes.io/serviceaccount/token
```

## Common Issues / Troubleshooting

- **403 Forbidden from Pod** → SA has no RBAC bindings; add a RoleBinding with the correct Role
- **Token not mounted** → `automountServiceAccountToken: false` set on SA or Pod; remove it or set to `true`
- **Wrong namespace** → SA is namespace-scoped; a Pod in `dev` cannot use a SA from `prod`
- **`serviceaccount not found`** → SA must exist before the Pod is created; create SA first
- **Old token not working** → Kubernetes 1.24+ tokens are short-lived; rotate or use `kubectl create token`
- **Pod can't pull image** → SA missing `imagePullSecrets`; patch the SA or add `imagePullSecrets` to the Pod spec directly

## Related Notes

- [[RBAC]] — Grants permissions to ServiceAccounts via RoleBindings
- [[Secrets]] — Older clusters stored SA tokens as Secrets; 1.24+ uses projected volumes
- [[Pods]] — Every Pod runs as a ServiceAccount
- [[Namespaces]] — ServiceAccounts are namespace-scoped
- [[Image Security]] — SA can carry `imagePullSecrets` for private registries
- [[kube-apiserver]] — SA tokens are validated here during authentication

## Key Mental Model

Think of a ServiceAccount as a **badge for your Pod**. Without a badge, the Pod can still run — it just can't open any doors inside the cluster (call the API). [[RBAC]] is the access control list that says which doors each badge can open. Always issue the most restrictive badge possible, and disable automounting for Pods that don't need API access at all.
