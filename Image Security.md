# Image Security
## Overview

**Image Security** in Kubernetes focuses on ensuring that container images are **trusted, scanned, minimal, and immutable** before running in the cluster.

Since Pods are created from images, an insecure image = a pre-packaged vulnerability launcher. Kubernetes does not magically secure images — it runs exactly what you give it, bugs and all.

## Why Image Security Matters

Risks of insecure images:
- Embedded malware or backdoors
- Outdated packages with CVEs
- Hardcoded secrets or credentials
- Running as root inside containers
- Large attack surface from unnecessary tools

Kubernetes assumes:

> “You built it. You trust it.”
> That assumption must be engineered, not hoped for.

## Use Trusted Image Sources

Always pull images from:
- Official registries (Docker Hub Official, Bitnami, etc.)
- Private registries (Harbor, ECR, GCR, ACR)
- Signed and verified repositories

Avoid random public images.

Example:

```bash
image: nginx:1.25.3
```

Instead of:

```bash
image: nginx:latest
```

## Avoid Latest Tag

latest is unpredictable and breaks reproducibility.

Problems:
- Different image every deployment
- Hard to rollback
- Supply-chain risk

Always use fixed tags or digests:

```bash
image: nginx@sha256:<digest>
```

## Image Scanning

Scan images for vulnerabilities before deployment.

Common tools:
- Trivy
- Clair
- Anchore
- Snyk

Example scan:

```bash
trivy image myapp:1.0
```

This detects:
- CVEs
- Misconfigurations
- Secrets accidentally baked into image

## Use Minimal Base Images

Smaller images = smaller attack surface.

Prefer:
- alpine
- distroless
- scratch

Avoid:
- Full Ubuntu / CentOS unless required

Example secure Dockerfile:

```dockerfile
FROM gcr.io/distroless/base
COPY app /app
USER 1001
CMD ["/app"]
```

No shell. No package manager. Nothing to exploit.

## Run Containers as Non-Root

Containers should **never run as root** unless absolutely necessary.

Set security context:

```yaml
securityContext:
  runAsUser: 1000
  runAsNonRoot: true
```

## Use Read-Only Filesystems

Prevent attackers from modifying container runtime.

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

## Image Pull Policies

Control when images are pulled:

```yaml
imagePullPolicy: IfNotPresent
```

Options:
- Always → pulls every time (good for dev)
- IfNotPresent → stable environments
- Never → air-gapped clusters

## Private Registry Authentication

Use [[Secrets]] to authenticate securely.

Create registry secret:

```bash
kubectl create secret docker-registry regcred \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<password>
```

Attach to Pod:

```yaml
imagePullSecrets:
- name: regcred
```

## Enforce Image Policies (Admission Controllers)

Use:
- [[Admission Controller]]
- OPA Gatekeeper
- Kyverno

To enforce rules like:
- No latest tag
- Only approved registries
- Signed images only

Example policy idea:

> “Only images from registry.company.com may run.”

## Image Signing (Supply Chain Security)

Use tools like:
- Cosign
- Notary

This ensures images are not tampered with.

Concept:

```bash
Build → Sign → Verify → Run
```

Without signature verification, you’re trusting the network blindly.

## Best Practices Summary

- Use trusted registries
- Pin versions (no latest)
- Scan images continuously
- Use minimal base images
- Run as non-root
- Use read-only filesystem
- Store credentials in Secrets
- Enforce policies via admission control
- Sign and verify images

## Key Mental Model

Kubernetes is not a firewall.
It is an execution engine.

If you hand it a poisoned image, it will faithfully run the poison at scale.

Cluster security begins **before the Pod exists** — at image build time.