---
tags: [cka/architecture, security]
aliases: [SecurityContext, runAsUser, capabilities, seccomp]
---

# Security Contexts

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Pods]], [[RBAC]], [[Image Security]], [[Namespaces]]

## Overview

A **Security Context** defines **privilege and access control settings** for a Pod or Container. It controls whether containers run as root, can escalate privileges, write to the filesystem, and what Linux capabilities they have. Security contexts are the **user permission model** for workloads in Kubernetes.

## Where to Define It

Security contexts can be applied at two levels:

| Level | Scope |
|---|---|
| `spec.securityContext` (Pod) | Applies to all containers in the Pod |
| `spec.containers[].securityContext` (Container) | Overrides Pod settings for that container |

## Core Settings

### Run as Non-Root (Most Important)

```yaml
securityContext:
  runAsUser: 1000         # UID to run as
  runAsGroup: 3000        # GID to run as
  runAsNonRoot: true      # Fail if image runs as root (UID 0)
```

### Prevent Privilege Escalation

Blocks `setuid` binaries and sudo-style escalation:

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

### Read-Only Root Filesystem

Prevents writing files, installing tools, or modifying binaries at runtime:

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

### Linux Capabilities

Drop all capabilities first, then add only what's needed:

```yaml
securityContext:
  capabilities:
    drop:
    - ALL
    add:
    - NET_BIND_SERVICE   # Allow binding to ports < 1024
```

Common capabilities:
- `NET_BIND_SERVICE` — bind ports below 1024
- `NET_ADMIN` — network interface management
- `SYS_PTRACE` — debugging
- `ALL` — all capabilities (never add this)

### Seccomp Profile

Restrict which syscalls a container can make to the kernel:

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault   # Use container runtime's default profile
    # type: Localhost      # Custom profile from node
    # type: Unconfined     # No restriction (avoid)
```

### fsGroup (Shared Volume Permissions)

Set group ownership for mounted volumes:

```yaml
spec:
  securityContext:
    fsGroup: 2000   # All volume files owned by GID 2000
```

## Complete Secure Pod Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:             # Pod-level
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault

  containers:
  - name: app
    image: myapp:1.0
    securityContext:           # Container-level (overrides Pod)
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
```

## Privileged Containers

Never use unless absolutely required (e.g., some node-level tooling):

```yaml
securityContext:
  privileged: true   # Gives container near-root access to the host
```

## Key Commands

```bash
# Check what user a container is running as
kubectl exec -it <pod> -- id

# Check capabilities
kubectl exec -it <pod> -- cat /proc/1/status | grep Cap

# Decode capability bitmap
capsh --decode=<hex_value>

# Check if filesystem is read-only
kubectl exec -it <pod> -- touch /test-file  # Should fail if readOnly

# Describe pod to see security context
kubectl describe pod <pod>
# Look for: Security Context section
```

## Common Issues / Troubleshooting

- **`permission denied` errors** → container running as non-root but file not owned by that UID; fix volume permissions with `fsGroup`
- **Container fails to start** → `runAsNonRoot: true` but image's USER is root; fix the image or override `runAsUser`
- **App can't write temp files** → `readOnlyRootFilesystem: true`; add an `emptyDir` volume for `/tmp`
- **Capability errors** → dropped `ALL` but app needs a capability; add it back explicitly

## Related Notes

- [[Pods]] — Security context defined in Pod spec
- [[RBAC]] — Controls API access; security context controls host access
- [[Image Security]] — Secure images complement secure contexts
- [[Namespaces]] — Pod Security Standards enforce context rules at namespace level

## Key Mental Model

Containers share the host kernel. Security Context is the **guardrail** that keeps a container from touching things it should never see. Start with maximum restriction (drop ALL, readOnly, runAsNonRoot) and add back only what's explicitly required. **Zero trust at the container level.**
