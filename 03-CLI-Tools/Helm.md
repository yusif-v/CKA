---
tags: [cka/architecture, cli, operations]
aliases: [Helm, Helm Chart, Helm Release, Package Manager]
---

# Helm

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubectl]], [[Deployments]], [[ConfigMap]], [[Secrets]], [[Namespaces]], [[RBAC]]

## Overview

**Helm** is the **package manager for Kubernetes**. It bundles Kubernetes manifests into reusable, versioned packages called **Charts**. Helm manages the full lifecycle of an application — install, upgrade, rollback, and uninstall — as a single atomic unit called a **Release**.

> [!tip] Exam Tip
> Know the four core Helm concepts: **Chart**, **Repository**, **Release**, and **Values**. The CKA may test `helm install`, `helm upgrade`, `helm rollback`, and `helm repo` commands.

## Core Concepts

| Concept | Description |
|---|---|
| **Chart** | Package of pre-configured Kubernetes resources (like a `.deb` or `.rpm`) |
| **Repository** | Remote registry that hosts and serves Charts |
| **Release** | A running instance of a Chart installed in the cluster |
| **Values** | Configuration inputs that customize a Chart at install time |
| **Revision** | Versioned snapshot of a Release — each upgrade creates a new revision |

---

## How Helm Works

```
Chart (template) + Values → Rendered Manifests → kubectl apply → Release
```

Helm stores release state as [[Secrets]] in the target namespace — no Tiller, no server-side component (Helm 3).

---

## Helm 2 vs Helm 3

| Feature | Helm 2 | Helm 3 |
|---|---|---|
| Server component | Tiller (in-cluster) | ❌ None (client-only) |
| RBAC requirement | Tiller needs cluster-admin | Uses your [[kubectl]] credentials |
| Release storage | ConfigMaps in `kube-system` | Secrets in release namespace |
| 3-way merge | ❌ | ✅ |

> [!note]
> The CKA uses **Helm 3**. Tiller is gone — Helm is now a pure client-side tool.

---

## Chart Structure

```
mychart/
├── Chart.yaml          # Chart metadata (name, version, description)
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes manifest templates (Go templating)
│   ├── deployment.yaml
│   ├── service.yaml
│   └── _helpers.tpl    # Reusable template helpers
└── charts/             # Dependent sub-charts
```

### Chart.yaml

```yaml
apiVersion: v2
name: mychart
description: A simple web application chart
version: 1.0.0        # Chart version
appVersion: "1.25.0"  # App version inside the chart
```

### values.yaml

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80
```

---

## Repository Management

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# List added repositories
helm repo list

# Update repository cache
helm repo update

# Remove a repository
helm repo remove bitnami

# Search charts in repos
helm search repo nginx

# Search Artifact Hub (public)
helm search hub nginx
```

---

## Installing Charts

```bash
# Install with default values
helm install my-release bitnami/nginx

# Install into a specific namespace (creates ns if --create-namespace is set)
helm install my-release bitnami/nginx \
  --namespace web \
  --create-namespace

# Override values inline
helm install my-release bitnami/nginx \
  --set replicaCount=3 \
  --set image.tag=1.26

# Override values with a file
helm install my-release bitnami/nginx \
  --values custom-values.yaml

# Dry run (render manifests without installing)
helm install my-release bitnami/nginx --dry-run

# Generate YAML only (no install, no cluster needed)
helm template my-release bitnami/nginx
```

---

## Managing Releases

```bash
# List all releases (current namespace)
helm list

# List across all namespaces
helm list -A

# Show release status
helm status my-release

# Show rendered manifest of a release
helm get manifest my-release

# Show values used for a release
helm get values my-release

# Show all release info
helm get all my-release
```

---

## Upgrading Releases

```bash
# Upgrade with new chart version or values
helm upgrade my-release bitnami/nginx

# Upgrade and override values
helm upgrade my-release bitnami/nginx \
  --set replicaCount=5

# Upgrade with a values file
helm upgrade my-release bitnami/nginx \
  --values custom-values.yaml

# Install if not exists, upgrade if it does
helm upgrade --install my-release bitnami/nginx
```

---

## Rollback

```bash
# View release history (revisions)
helm history my-release

# Rollback to previous revision
helm rollback my-release

# Rollback to a specific revision
helm rollback my-release 2
```

---

## Uninstalling Releases

```bash
# Uninstall and remove all resources
helm uninstall my-release

# Uninstall from a specific namespace
helm uninstall my-release --namespace web

# Keep history after uninstall (allows rollback)
helm uninstall my-release --keep-history
```

---

## Key Commands Summary

```bash
# Repo
helm repo add <name> <url>
helm repo update
helm search repo <keyword>

# Install / Upgrade
helm install <release> <chart>
helm upgrade <release> <chart>
helm upgrade --install <release> <chart>

# Inspect
helm list -A
helm status <release>
helm get values <release>
helm get manifest <release>
helm history <release>

# Rollback / Uninstall
helm rollback <release> <revision>
helm uninstall <release>

# Debug
helm template <release> <chart>
helm install <release> <chart> --dry-run
```

---

## Common Issues / Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| `Error: release not found` | Wrong namespace or name | `helm list -A` to find the release |
| Resources not updating after upgrade | Values not changed | Use `--set` or `--values` to override |
| `helm install` fails on re-install | Release already exists | Use `helm upgrade --install` instead |
| Rollback fails | History was cleared | Use `--keep-history` on uninstall |
| Chart not found | Repo cache stale | Run `helm repo update` |
| Permission denied | RBAC missing for current user | Check [[RBAC]] rules for the service account |

---

## Related Notes

- [[kubectl]] — Helm uses the same kubeconfig and cluster context
- [[Deployments]] — Most Charts deploy and manage Deployments
- [[Secrets]] — Helm stores release state as Secrets in the release namespace
- [[Namespaces]] — Each Helm release is scoped to a namespace
- [[RBAC]] — Helm uses your current kubectl credentials for all operations
- [[ConfigMap]] — Chart values can be injected as ConfigMaps

---

## Key Mental Model

Helm is **apt/yum for Kubernetes**. Without it, you write and manage every manifest by hand. With it, you install a full application stack — Deployments, Services, Secrets, RBAC — in a single command, and roll it back just as easily if something breaks.
