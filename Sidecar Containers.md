# Sidecar Containers
## Overview

**Sidecar Containers** are secondary containers in a Pod that **enhance or support the main application container**.

They run **alongside the main container**, sharing the same network and storage, but perform auxiliary tasks.

Sidecars follow the **“one main, many helpers”** pattern.

## Key Characteristics

- Run in the **same Pod** as the main container
- Share **volumes and network namespace** with main container
- Typically **not critical for main container startup**
- Can be restarted independently along with the Pod

## Common Use Cases

- **Logging agents** (collect, ship, or transform logs)
- **Proxies** (service mesh, API gateway, traffic routing)
- **Monitoring and metrics exporters**
- **Configuration updaters** or sync agents
- **Adapters** that transform data between services

## Pod Spec Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sidecar-demo
spec:
  containers:
  - name: main-app
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
  - name: log-sidecar
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/access.log"]
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
  volumes:
  - name: shared-logs
    emptyDir: {}
```

**Flow:**
- Main container writes logs to shared volume
- Sidecar reads logs and forwards them elsewhere

## Patterns and Best Practices

- **Sidecar pattern:** Add functionality without modifying main container
- **Ambassador pattern:** Sidecar handles communication with external service
- Keep sidecars **focused and lightweight**
- Use shared volumes or localhost for communication
- Avoid unrelated tasks in sidecars

## Observability

Check containers in a Pod:

```bash
kubectl get pod sidecar-demo
kubectl describe pod sidecar-demo
```

Exec into sidecar container:

```bash
kubectl exec -it sidecar-demo -c log-sidecar -- sh
```

## Sidecars vs 

|**Feature**|**Sidecar**|**Init Container**|
|---|---|---|
|Runs before main container?|No|Yes|
|Runs continuously?|Yes|No|
|Purpose|Enhance main container|Prepare environment|
|Restart behavior|Along with Pod|Pod restart if failed|

## Key Mental Model

Sidecars are **support specialists in the same workspace**:
- Main container = core service
- Sidecar = assistant that adds functionality (logging, monitoring, proxying)

Together, they form a **cohesive unit of work** inside the Pod.