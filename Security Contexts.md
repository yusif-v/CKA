# Security Contexts
## Overview

A **Security Context** defines **privilege and access control settings** for a Pod or Container.

It answers questions like:
- Should this container run as root?
- Can it modify the filesystem?
- Can it escalate privileges?
- Which Linux capabilities are allowed?

If Kubernetes is the operating system of your cluster, Security Context is the **user permission model** for workloads.

## Where You Can Define It

Security Context can be applied at two levels:

|**Level**|**Scope**|
|---|---|
|Pod|Applies to all containers in the Pod|
|Container|Overrides Pod settings for that container|

## Running as Non-Root (Most Important Rule)

Containers should never run as root unless absolutely required.

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 3000
  runAsNonRoot: true
```

Why this matters:

If an attacker breaks into the container, they gain only limited permissions — not full system control.

## Prevent Privilege Escalation

Stops processes from gaining more privileges (e.g., via setuid binaries).

```yaml
securityContext:
  allowPrivilegeEscalation: false
```

This blocks a common container-escape technique.

## Read-Only Root Filesystem

Prevents attackers from writing files, installing tools, or modifying binaries.

```yaml
securityContext:
  readOnlyRootFilesystem: true
```

This turns the container into an immutable environment.

## Dropping Linux Capabilities

Linux capabilities are fine-grained permissions like:
- NET_ADMIN (network control)
- SYS_ADMIN (basically root power)

Drop everything unless explicitly needed.

```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

Add only what is required:

```yaml
securityContext:
  capabilities:
    add:
      - NET_BIND_SERVICE
```

Principle: **Start from zero trust. Add permissions intentionally.**

## Seccomp Profiles (System Call Filtering)

Seccomp restricts which system calls a container can make to the kernel.

```yaml
securityContext:
  seccompProfile:
    type: RuntimeDefault
```

This blocks dangerous syscalls used in many exploits.

## SELinux / AppArmor (If Enabled on Nodes)

These provide Mandatory Access Control at OS level.

Example:

```yaml
securityContext:
  seLinuxOptions:
    level: "s0:c123,c456"
```

These are advanced but powerful for hardened environments.

## Example: Secure Pod Configuration

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    runAsNonRoot: true
    fsGroup: 2000

  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      runAsUser: 1000
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
          - ALL
      seccompProfile:
        type: RuntimeDefault
```

This configuration:
- Runs without root
- Cannot gain privileges
- Cannot write to system files
- Has zero extra kernel powers
- Uses restricted syscall set

That is what “container hardening” actually looks like.

## fsGroup (Shared Volume Permissions)

When Pods mount volumes, file permissions can break.
fsGroup ensures containers can read/write shared storage safely.

```yaml
securityContext:
  fsGroup: 2000
```

Kubernetes adjusts volume ownership automatically.

## Common Mistakes to Avoid

Running containers as root “just because it works”.

Leaving default capabilities enabled.

Allowing writable root filesystems.

Skipping syscall filtering.

These shortcuts trade convenience for attack surface.

## Best Practices Checklist

✔ Always set runAsNonRoot
✔ Drop ALL capabilities first
✔ Disable privilege escalation
✔ Use read-only filesystem
✔ Enable seccomp profile
✔ Apply settings at Pod level when possible
✔ Only add permissions explicitly required

## Mental Model

Containers are not tiny VMs.
They share the host kernel.

Security Context is the guardrail that keeps a container from touching things it should never see.

Without it, isolation is thinner than most people assume.

Next layer of the rabbit hole is Pod Security Standards and policy enforcement, where you stop insecure specs from ever being admitted to the cluster in the first place.