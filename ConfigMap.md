# ConfigMap
## Overview

A **ConfigMap** is a Kubernetes object used to **store configuration data separately from containers**.

It allows Pods to consume configuration **without rebuilding images**, supporting **declarative and dynamic config management**.

## Purpose

- Decouple configuration from container images
- Make workloads portable
- Enable environment-specific settings
- Support dynamic updates for some use cases

Works closely with [[Pods]] and [[Deployments]].

## Data Formats

ConfigMap stores key-value pairs in three ways:

1. **Literal key-value pairs** (imperative)

```
kubectl create configmap my-config --from-literal=key1=value1
```

2. **From file**

```
kubectl create configmap my-config --from-file=config.properties
```

3. **From directory**

```
kubectl create configmap my-config --from-file=./configs
```

## YAML Manifest Example

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: DEBUG
  API_URL: https://api.example.com
```

- data stores string key-value pairs
- All keys and values are **UTF-8 strings**

## Consuming ConfigMaps in Pods

### 1. Environment Variables

```
spec:
  containers:
  - name: app
    image: myapp:latest
    envFrom:
    - configMapRef:
        name: app-config
```

### 2. Mounted as Files

```
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: config
      mountPath: /etc/config
  volumes:
  - name: config
    configMap:
      name: app-config
```

## Updating ConfigMaps

- ConfigMap itself can be updated using kubectl apply -f configmap.yaml
- Pods **mounted as volumes** may see changes automatically
- Pods using environment variables **do not update automatically**; require restart

## Limitations

- Data size < 1MB per ConfigMap
- Environment variable updates require Pod restart
- Not suitable for secrets (use [[Secrets]] instead)

## Observing ConfigMaps

```bash
kubectl get configmap
kubectl describe configmap app-config
```

Inspect mounted files inside a Pod:

```bash
kubectl exec -it <pod-name> -- cat /etc/config/LOG_LEVEL
```

## Best Practices

- Use one ConfigMap per application or logical component
- Use clear naming conventions
- Store environment-specific overrides in separate ConfigMaps
- Avoid embedding secrets — use [[Secrets]] instead

## Key Mental Model

**ConfigMap = externalized configuration**.

It’s the bridge between **code** (container image) and **environment-specific settings**.

Think of it as a **dictionary of strings** that Pods can read without knowing the source.