---
tags: [cka/architecture, configuration]
aliases: [ConfigMap, config map, application config]
---

# ConfigMap

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Secrets]], [[Pods]], [[Deployments]], [[Environment Variables]], [[Namespaces]]

## Overview

A **ConfigMap** is a Kubernetes object used to **store non-sensitive configuration data** separately from container images. It allows [[Pods]] to consume configuration without rebuilding images, enabling environment-specific settings and portable workloads.

## Purpose

- Decouple configuration from container images
- Enable environment-specific settings (dev/staging/prod)
- Support dynamic updates for volume-mounted configs
- Works closely with [[Pods]], [[Deployments]], and [[Environment Variables]]

## Creating ConfigMaps

### Imperatively

```bash
# From literals
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=API_URL=https://api.example.com

# From a file
kubectl create configmap app-config --from-file=config.properties

# From a directory
kubectl create configmap app-config --from-file=./configs/
```

### Declaratively

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  LOG_LEVEL: "debug"
  API_URL: "https://api.example.com"
  config.properties: |
    max_connections=100
    timeout=30
```

## Consuming ConfigMaps in Pods

### As Environment Variables (all keys)

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    envFrom:
    - configMapRef:
        name: app-config
```

### As Individual Environment Variables

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: LOG_LEVEL
```

### Mounted as Files (supports live updates)

```yaml
spec:
  volumes:
  - name: config-vol
    configMap:
      name: app-config
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config-vol
      mountPath: /etc/config
      readOnly: true
```

Each key becomes a file at `/etc/config/<key>`.

## Update Behavior

| Consumption Method | Updates Propagate? |
|---|---|
| `envFrom` / `env` | ❌ No — Pod must restart |
| Volume mount | ✅ Yes — eventually consistent (~60s) |

## Key Commands

```bash
# List ConfigMaps
kubectl get configmap
kubectl get cm

# Describe ConfigMap (shows data)
kubectl describe configmap app-config

# View raw YAML
kubectl get configmap app-config -o yaml

# Edit ConfigMap
kubectl edit configmap app-config

# Delete ConfigMap
kubectl delete configmap app-config

# Check mounted config inside pod
kubectl exec -it <pod> -- cat /etc/config/LOG_LEVEL
```

## Common Issues / Troubleshooting

- **Pod not picking up changes** → env vars are static at Pod start; restart the Pod
- **Key not found** → typo in key name; `kubectl describe configmap` to see all keys
- **ConfigMap doesn't exist** → Pod stays in `Pending`/`CreateContainerConfigError`; create the ConfigMap first
- **Wrong namespace** → ConfigMap must be in same namespace as Pod
- **Size limit** → ConfigMaps have a 1MB limit; use volumes or external storage for large configs

## Related Notes

- [[Secrets]] — For sensitive configuration data (passwords, tokens)
- [[Environment Variables]] — How ConfigMap data is exposed to containers
- [[Pods]] — Consumer of ConfigMap data
- [[Deployments]] — Trigger rolling update after ConfigMap changes via annotation

## Key Mental Model

**ConfigMap = externalized configuration**. It's the bridge between **code** (the container image, which never changes) and **environment-specific settings** (which change constantly). Think of it as a **dictionary of strings** that Pods read without knowing or caring where it lives.
