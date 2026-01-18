# Environment Variables
## Overview

**Environment Variables** provide a way to **pass configuration into containers at runtime**.

They are commonly used to configure applications without changing container images.

Environment variables are defined in the Pod specification.

## Why Use Environment Variables

- Separate configuration from code
- Enable environment-specific behavior
- Avoid rebuilding images
- Integrate with [[ConfigMap]]s and [[Secrets]]

They are simple, explicit, and widely supported.

## Defining Environment Variables Directly

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: env-demo
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: LOG_LEVEL
      value: "debug"
    - name: APP_MODE
      value: "production"
```

These values are injected when the container starts.

## Using ConfigMaps

### Import All Keys

```yaml
envFrom:
- configMapRef:
    name: app-config
```

Each key becomes an environment variable.

### Import a Single Key

```yaml
env:
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: LOG_LEVEL
```

## Using Secrets
### Import All Keys

```yaml
envFrom:
- secretRef:
    name: db-secret
```

### Import a Single Secret Key

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

## Downward API

Environment variables can expose Pod metadata:

```yaml
env:
- name: POD_NAME
  valueFrom:
    fieldRef:
      fieldPath: metadata.name
```

Common fields:
- Pod name
- Namespace
- Node name
- Resource limits

## Update Behavior

- Environment variables are **static**
- Changes to ConfigMaps or Secrets **do not update** running containers
- Pod restart is required to apply changes

For dynamic updates, use volume mounts.

## Observability

View environment variables:

```bash
kubectl describe pod <pod-name>
```

Inside the container:

```bash
kubectl exec -it <pod-name> -- env
```

## Best Practices

- Use ConfigMaps for non-sensitive values
- Use Secrets for sensitive values
- Avoid hardcoding values in manifests
- Keep naming consistent and uppercase

## Key Mental Model

Environment variables are **startup instructions**.

Once the container starts, the values are frozen.
If the environment changes, the container must be reborn.