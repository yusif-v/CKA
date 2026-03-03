---
tags: [cka/architecture, security]
aliases: [Image Pull, Registry, imagePullSecrets, Image Scanning]
---

# Image Security

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Secrets]], [[Security Contexts]], [[RBAC]], [[Pods]], [[Deployments]]

## Overview

**Image Security** in Kubernetes covers the full lifecycle of container images: where they come from, how they're verified, and how access to private registries is managed. Kubernetes is an execution engine — if you hand it a compromised image, it will faithfully run it at scale.

## Image Naming and Tags

```yaml
# Full image reference
image: registry.example.com:5000/team/app:v1.2.3

# Components:
# registry.example.com:5000  = registry host + port
# team/app                   = repository
# v1.2.3                     = tag
```

> [!warning]
> Never use `latest` in production — it's mutable and unpredictable. Always pin to a specific version tag or image digest.

## Image Pull Policy

```yaml
spec:
  containers:
  - name: app
    image: myapp:1.2.3
    imagePullPolicy: IfNotPresent   # Default when tag is not 'latest'
```

| Policy | Behavior |
|---|---|
| `Always` | Pull on every Pod start (good for dev/CI) |
| `IfNotPresent` | Use cached image if available (default for tagged images) |
| `Never` | Never pull; fail if not cached (air-gapped environments) |

> Note: `imagePullPolicy` defaults to `Always` when `image` tag is `latest` or unspecified.

## Private Registry Authentication

### Create a docker-registry Secret

```bash
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

### Use imagePullSecrets in Pod

```yaml
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: app
    image: registry.example.com/team/app:1.0
```

### Attach imagePullSecrets to a ServiceAccount

Pods using that ServiceAccount automatically get the pull secret:

```bash
kubectl patch serviceaccount default \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'
```

## Security Best Practices

### Use Minimal Base Images

```dockerfile
# Bad: Large attack surface
FROM ubuntu:latest

# Good: Minimal
FROM gcr.io/distroless/static:nonroot
```

### Run as Non-Root

```yaml
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
```

See [[Security Contexts]] for full details.

### Use Read-Only Filesystem

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

### Image Signing (Supply Chain Security)

Use tools like **Cosign** or **Notary** to sign and verify images:

```bash
# Sign an image
cosign sign registry.example.com/team/app:1.0

# Verify signature
cosign verify registry.example.com/team/app:1.0 --key cosign.pub
```

Without signing verification, you're trusting the registry completely.

## Enforce Image Policies via Admission Controllers

Use admission controllers or policy engines to enforce rules:
- Only images from approved registries
- No `latest` tag
- Only signed images

Tools: **OPA Gatekeeper**, **Kyverno**, **ImagePolicyWebhook**

Example policy idea:
> "Only images from `registry.company.com` may run in production namespace."

## Key Commands

```bash
# Check what image a pod is running
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].image}'

# Describe pod for image pull errors
kubectl describe pod <pod>
# Look for: ImagePullBackOff, ErrImagePull events

# List image pull secrets
kubectl get secrets --field-selector type=kubernetes.io/dockerconfigjson

# Inspect a docker-registry secret
kubectl get secret regcred -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d

# Check if image is cached on node
# (requires SSH to node)
crictl images
```

## Common Issues / Troubleshooting

- **`ImagePullBackOff`** → wrong credentials or image doesn't exist; check `kubectl describe pod`
- **`ErrImageNeverPull`** → `imagePullPolicy: Never` but image not cached on node
- **Private registry not accessible** → `imagePullSecrets` not set or wrong registry URL
- **`latest` tag causing stale image** → set `imagePullPolicy: Always` or pin to a digest
- **Node can't reach registry** → network policy or firewall blocking egress from node

## Related Notes

- [[Secrets]] — docker-registry Secrets store registry credentials
- [[Security Contexts]] — Complement image security with runtime restrictions
- [[Pods]] — imagePullSecrets defined in Pod spec
- [[RBAC]] — Restrict who can create Pods with sensitive imagePullSecrets

## Key Mental Model

Kubernetes is not a firewall — it's an **execution engine**. It will faithfully run whatever image you give it, at scale. Cluster security begins **before the Pod exists** — at image build time, in the registry, and through policy enforcement at admission. Secure the supply chain, not just the runtime.
