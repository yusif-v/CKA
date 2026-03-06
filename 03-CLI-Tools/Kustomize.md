---
tags: [cka/architecture, cli]
aliases: [kustomize, kustomization, overlay, base, patch]
---

# Kustomize

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubectl]], [[Deployments]], [[ConfigMap]], [[Namespaces]], [[Labels]], [[Secrets]]

## Overview

**Kustomize** is a template-free configuration management tool built directly into [[kubectl]]. It lets you define a **base** set of Kubernetes manifests and apply **overlays** on top — per environment, per team, or per cluster — without duplicating YAML or using templating engines. No new syntax to learn: it's just YAML transforming YAML.

> [!note]
> Kustomize is built into kubectl since v1.14. No separate install needed — `kubectl apply -k` is all you need.

---

## Core Concepts

| Concept | Description |
|---|---|
| **Base** | The original, shared set of manifests |
| **Overlay** | Environment-specific patches layered on top of the base |
| **kustomization.yaml** | The control file that wires everything together |
| **Patch** | A targeted modification to a specific field in a resource |
| **Generator** | Dynamically creates [[ConfigMap]]s or [[Secrets]] from files/literals |

### Kustomize vs Helm

| Feature | Kustomize | Helm |
|---|---|---|
| Built into kubectl | ✅ Yes | ❌ No |
| Templating language | ❌ None (pure YAML) | ✅ Go templates |
| Package registry | ❌ No | ✅ Yes (Artifact Hub) |
| Best for | Config variants of your own apps | Installing third-party software |
| GitOps friendly | ✅ Very | ✅ Yes |

---

## Directory Structure

A typical Kustomize project looks like this:

```
app/
├── base/
│   ├── kustomization.yaml
│   ├── deployment.yaml
│   └── service.yaml
└── overlays/
    ├── dev/
    │   └── kustomization.yaml
    └── prod/
        ├── kustomization.yaml
        └── replica-patch.yaml
```

---

## kustomization.yaml — The Control File

Every directory managed by Kustomize needs a `kustomization.yaml`.

### Base kustomization.yaml

```yaml
# base/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- deployment.yaml
- service.yaml
```

### Overlay kustomization.yaml

```yaml
# overlays/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

# Point to the base
bases:
- ../../base

# Add a name prefix to all resources
namePrefix: prod-

# Override namespace
namespace: production

# Add labels to all resources
commonLabels:
  env: production

# Apply patches
patches:
- path: replica-patch.yaml
```

---

## Patches

Patches modify specific fields in base resources without touching the base files.

### Strategic Merge Patch

Merges the patch into the existing resource — good for simple field overrides:

```yaml
# replica-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 5
```

### JSON 6902 Patch

Surgical field-level operations — good for precise changes:

```yaml
# overlays/prod/kustomization.yaml
patches:
- target:
    kind: Deployment
    name: my-app
  patch: |-
    - op: replace
      path: /spec/replicas
      value: 5
    - op: add
      path: /spec/template/spec/containers/0/resources
      value:
        limits:
          cpu: "500m"
          memory: "256Mi"
```

---

## ConfigMap and Secret Generators

Kustomize can generate [[ConfigMap]]s and [[Secrets]] from files or literals, and automatically appends a content hash to the name — forcing [[Pods]] to restart when the config changes.

```yaml
# kustomization.yaml
configMapGenerator:
- name: app-config
  literals:
  - LOG_LEVEL=debug
  - API_URL=https://api.example.com

secretGenerator:
- name: db-credentials
  literals:
  - username=admin
  - password=s3cr3t
  type: Opaque
```

> [!tip]
> The auto-appended hash (e.g., `app-config-7f4d9b2c`) ensures that any change to the config triggers a rolling update of [[Deployments]] that reference it.

---

## Image Overrides

Override container image tags without editing manifests — useful for CI/CD pipelines:

```yaml
# kustomization.yaml
images:
- name: myapp
  newTag: v2.1.0

- name: nginx
  newName: my-registry/nginx
  newTag: "1.25"
```

---

## Key Commands

```bash
# Preview rendered output (does NOT apply to cluster)
kubectl kustomize ./base
kubectl kustomize ./overlays/prod

# Apply a kustomization directory
kubectl apply -k ./overlays/prod

# Delete resources from a kustomization
kubectl delete -k ./overlays/prod

# Diff against live cluster state
kubectl diff -k ./overlays/prod

# Use standalone kustomize binary (if installed)
kustomize build ./overlays/prod | kubectl apply -f -
```

---

## Real-World Example

Base deployment:

```yaml
# base/deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

Production overlay — scale up and add resource limits:

```yaml
# overlays/prod/kustomization.yaml
bases:
- ../../base
namespace: production
namePrefix: prod-
commonLabels:
  env: production
patches:
- path: scale-patch.yaml
```

```yaml
# overlays/prod/scale-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 10
  template:
    spec:
      containers:
      - name: web
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
```

---

## Common Issues / Troubleshooting

- **`error: no kustomization file found`** → missing `kustomization.yaml` in target directory; check path
- **Patch not applying** → `metadata.name` in patch must exactly match the base resource name
- **Resources not found in overlay** → `bases:` path is relative; double-check `../../base` traversal
- **ConfigMap hash causes broken references** → use `disableNameSuffixHash: true` if you're managing rollouts manually
- **Wrong namespace applied** → `namespace:` in kustomization overrides all resources; verify it's set correctly in the right overlay

## Related Notes

- [[kubectl]] — `kubectl apply -k` and `kubectl kustomize` are the primary commands
- [[Deployments]] — Primary target for Kustomize patches and image overrides
- [[ConfigMap]] — Kustomize generators create and hash ConfigMaps automatically
- [[Secrets]] — Secret generators work identically to ConfigMap generators
- [[Namespaces]] — Overlays commonly override namespace per environment
- [[Labels]] — `commonLabels` field stamps all resources in a kustomization
- [[Dev Tools]] — Kustomize pairs with ArgoCD and Flux for GitOps workflows

## Key Mental Model

Kustomize is **inheritance for YAML**. The base is the parent class — shared, stable, never touched. Overlays are subclasses — they inherit everything and override only what differs. Dev gets 1 replica and debug logging. Prod gets 10 replicas and structured JSON logs. Same base, different reality.
