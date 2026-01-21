# Init Containers
## Overview

**Init Containers** are special containers that **run before the main containers** in a Pod start.

They are used to **prepare the environment**, perform setup tasks, or enforce preconditions.

## Key Characteristics

- Run **sequentially**, one at a time
- Must **complete successfully** before main containers start
- Share Pod volumes with main containers
- Can use different images than main containers
- Cannot be restarted independently — Pod restart if failed

## Common Use Cases

- **Initialize databases** or configuration files
- **Wait for services** or external dependencies
- **Set up secrets** or permissions
- **Run migrations**

## Pod Spec Example

```bash
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: init-myservice
    image: busybox
    command: ["sh", "-c", "echo initializing > /work-dir/ready"]
    volumeMounts:
    - name: work-dir
      mountPath: /work-dir
  containers:
  - name: main-app
    image: nginx
    volumeMounts:
    - name: work-dir
      mountPath: /usr/share/nginx/html
  volumes:
  - name: work-dir
    emptyDir: {}
```

**Flow:**
1. init-myservice runs first
2. Writes files to shared volume
3. Main container starts using pre-populated data

## Behavior Notes

- Init containers **block main containers** until they finish
- Failures cause **Pod restart** according to restartPolicy
- Useful for **synchronization and setup** without polluting main container images

## Observing Init Containers

Check init container status:

```bash
kubectl get pod init-demo
kubectl describe pod init-demo
```

Exec is not allowed while init container runs (since it may already be completed).

## Best Practices

- Keep init containers **lightweight and fast**
- Use separate images to avoid bloating main container
- Use shared volumes for communication
- Avoid making init containers long-running

## Key Mental Model

**Init Containers = preparation crew.**
They show up **before the show starts**, set everything up, then leave.
Main containers are the **performers** — ready to run because the groundwork is done.

They are essential for **reliable startup in complex Pods**.