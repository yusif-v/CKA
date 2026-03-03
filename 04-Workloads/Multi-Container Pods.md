---
tags: [cka/workloads, workloads]
aliases: [Sidecar, Multi-container, Ambassador, Adapter]
---

# Multi-Container Pods

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[Init Containers]], [[Services]], [[Namespaces]]

## Overview

A **Multi-Container Pod** runs **more than one container** within the same Pod. All containers share the same network namespace (IP + port space) and can share volumes for storage. They are scheduled together on the same Node and live and die together.

Use multi-container Pods for **tightly coupled processes** that need to share resources.

## Shared Resources Between Containers

- **Network**: All containers share `localhost` — container A can reach container B on `localhost:8080`
- **Volumes**: `emptyDir` and other volumes can be mounted by multiple containers
- **Lifecycle**: All containers start/stop together as part of the same Pod

## Container Patterns

### Sidecar Pattern

Adds features to the main container **without modifying its image**:

```yaml
containers:
- name: main-app
  image: nginx
- name: log-shipper
  image: fluentd
  volumeMounts:
  - name: logs
    mountPath: /var/log/nginx
```

Examples: log collectors, metrics exporters, config reloaders, service mesh proxies

### Ambassador Pattern

Proxies network connections on behalf of the main container:

```yaml
containers:
- name: app
  image: myapp
  env:
  - name: DB_HOST
    value: localhost:5432   # Talks to ambassador
- name: db-proxy
  image: db-proxy
  # Handles real DB connection externally
```

### Adapter Pattern

Transforms the main container's output to match an external interface:

```yaml
containers:
- name: app
  image: myapp   # Produces custom log format
- name: adapter
  image: log-adapter   # Converts to standard format
```

## Pod Spec Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-demo
spec:
  containers:
  - name: main-app
    image: nginx
    ports:
    - containerPort: 80
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx

  - name: sidecar-logger
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/nginx/access.log"]
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log/nginx

  volumes:
  - name: shared-logs
    emptyDir: {}
```

## Key Commands

```bash
# View containers in a pod
kubectl describe pod multi-container-demo

# Logs from specific container
kubectl logs multi-container-demo -c sidecar-logger

# Exec into specific container
kubectl exec -it multi-container-demo -c main-app -- /bin/sh

# Get all container names
kubectl get pod multi-container-demo -o jsonpath='{.spec.containers[*].name}'
```

## Common Issues / Troubleshooting

- **One container crashes, Pod restarts** → all containers restart together
- **Port conflict** → two containers in same Pod cannot bind same port
- **Volume mount path conflict** → containers using same mountPath overwrite each other's data
- **"which container" errors** → always use `-c <container-name>` flag for logs/exec in multi-container pods

## Related Notes

- [[Pods]] — The base unit that multi-container pods extend
- [[Init Containers]] — Run sequentially before main containers start
- [[Services]] — Routes traffic to the Pod as a whole (to its IP)

## Key Mental Model

A multi-container Pod is **a small ecosystem**. Containers share space and resources, cooperate to provide a single service. Sidecars, init containers, and adapters are just different specialist roles working together inside the same shared home.
