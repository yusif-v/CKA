---
tags: [cka/architecture, configuration]
aliases: [env vars, container environment, envFrom]
---

# Environment Variables

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[ConfigMap]], [[Secrets]], [[Pods]], [[Deployments]]

## Overview

**Environment Variables** provide a way to **pass configuration into containers at runtime**. They are defined in the Pod specification and can come from literal values, [[ConfigMap]]s, [[Secrets]], or Pod metadata (Downward API). They are injected when the container starts and **frozen for the lifetime of the container**.

## Defining Variables Directly

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: LOG_LEVEL
      value: "debug"
    - name: APP_MODE
      value: "production"
    - name: APP_PORT
      value: "8080"
```

## From ConfigMap

### Single key

```yaml
env:
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: LOG_LEVEL
```

### All keys (envFrom)

```yaml
envFrom:
- configMapRef:
    name: app-config
```

## From Secrets

### Single key

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

### All keys (envFrom)

```yaml
envFrom:
- secretRef:
    name: db-secret
```

## Combining Multiple Sources

```yaml
envFrom:
- configMapRef:
    name: app-config      # Non-sensitive config
- secretRef:
    name: app-secrets     # Sensitive config
env:
- name: EXTRA_VAR         # Literal override (takes precedence)
  value: "custom-value"
```

> [!note] Precedence: `env` entries override `envFrom` if keys conflict.

## Downward API (Pod Metadata)

Expose Pod's own metadata as environment variables:

```yaml
env:
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
- name: POD_NAMESPACE
  valueFrom:
    fieldRef:
      fieldPath: metadata.namespace
- name: NODE_NAME
  valueFrom:
    fieldRef:
      fieldPath: spec.nodeName
- name: CPU_LIMIT
  valueFrom:
    resourceFieldRef:
      containerName: app
      resource: limits.cpu
```

## Update Behavior

Environment variables are **static** — they are set at container start:

- Changes to [[ConfigMap]]s or [[Secrets]] **do NOT update** running containers
- Pod must be **restarted** to pick up new values
- For dynamic updates, use **volume mounts** instead

## Key Commands

```bash
# View all env vars in a pod
kubectl exec -it <pod> -- env

# View env vars via describe
kubectl describe pod <pod>
# Look for: Environment section

# Generate pod YAML with env var
kubectl run nginx --image=nginx --env="LOG_LEVEL=debug" --dry-run=client -o yaml
```

## Common Issues / Troubleshooting

- **Container not seeing updated ConfigMap value** → env vars are frozen; restart Pod
- **`CreateContainerConfigError`** → referenced ConfigMap or Secret doesn't exist
- **Key name collision in envFrom** → when two sources have same key, last one wins; use explicit `env` to control
- **Empty value** → key exists in ConfigMap but has empty value; check `kubectl describe configmap`

## Related Notes

- [[ConfigMap]] — Primary source for non-sensitive env vars
- [[Secrets]] — Source for sensitive env vars
- [[Pods]] — Where env vars are defined and consumed
- [[Deployments]] — Rolling restart after config changes: `kubectl rollout restart deployment/<n>`

## Key Mental Model

Environment variables are **startup instructions baked into the container**. Once the container starts, the values are frozen in memory. If the environment changes, the container must be reborn. For live config changes without restarts, use **volume-mounted** [[ConfigMap]]s instead.
