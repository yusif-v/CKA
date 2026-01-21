# Multi-container Pods
## Overview

A **Multi-container Pod** is a Pod that runs **more than one container**.

All containers in a Pod:
- Share the **same network namespace** (same IP and port space)
- Share **volumes** for storage
- Are scheduled **together on the same Node**

Use multi-container Pods for tightly coupled processes.

## Use Cases

- **Sidecar Containers**
    Examples: logging, monitoring, proxy, or configuration updater
    
- **Adapter Containers**
    Transform data for the main container
    
- **Ambassador Containers**
    Provide networking or service proxy functionality

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
  - name: sidecar-logger
    image: busybox
    command: ["sh", "-c", "tail -f /var/log/app.log"]
    volumeMounts:
    - name: shared-logs
      mountPath: /var/log
  volumes:
  - name: shared-logs
    emptyDir: {}
```

- emptyDir allows **shared storage** between containers
- Containers can communicate via localhost

## Communication Between Containers

- Containers in a Pod **share localhost**
- Ports can be accessed directly, e.g., localhost:8080
- No need for Services inside the same Pod

## Sidecar Pattern

- Adds features to the main container **without modifying it**
- Examples:
    - Log collectors
    - Proxy for outbound requests
    - Metrics exporters

## Init Containers

- Run **before main containers** start
- Perform setup tasks (e.g., migrations, configuration)
- Can share volumes with main containers

Example:

```yaml
initContainers:
- name: init-myservice
  image: busybox
  command: ["sh", "-c", "echo initializing > /work-dir/ready"]
  volumeMounts:
  - name: work-dir
    mountPath: /work-dir
```

## Best Practices

- Use multi-container Pods only when containers are **tightly coupled**
- Keep containers minimal and focused
- Avoid mixing unrelated processes
- Use volumes for communication, not external networking

## Observability

Check containers in a Pod:

```bash
kubectl get pod multi-container-demo
kubectl describe pod multi-container-demo
```

Exec into a specific container:

```bash
kubectl exec -it multi-container-demo -c sidecar-logger -- sh
```

## Key Mental Model

A multi-container Pod is **a small ecosystem**:
- Containers share **space and resources**
- They **cooperate to provide a single service**
- Sidecars, init containers, and adapters are just **different roles in the ecosystem**

Think: _one Pod, multiple specialists working together_.