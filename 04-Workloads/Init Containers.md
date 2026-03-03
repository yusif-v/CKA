---
tags: [cka/workloads, workloads]
aliases: [Init Container, initContainers]
---

# Init Containers

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[Multi-Container Pods]], [[kubelet]], [[Deployments]]

## Overview

**Init Containers** are special containers that **run and must complete before the main containers start**. They are used to prepare the environment, enforce pre-conditions, or perform setup tasks. Each init container runs to completion sequentially before the next one starts.

## Key Characteristics

- Run **sequentially** — one at a time, in order
- Must **complete successfully** before main containers start
- Share Pod volumes with main containers (handoff mechanism)
- Can use **different images** than main containers (e.g., use tools not in the main image)
- Pod **restarts if any init container fails** (according to `restartPolicy`)

## Common Use Cases

- Wait for a service or database to be ready before app starts
- Initialize a database schema or seed data
- Download configuration or certificates
- Set up file permissions on shared volumes
- Run database migrations

## Pod Spec Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: init-demo
spec:
  initContainers:
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nc -z db-service 5432; do echo waiting; sleep 2; done']

  - name: init-config
    image: busybox
    command: ['sh', '-c', 'echo "app_config=true" > /config/settings.conf']
    volumeMounts:
    - name: config-vol
      mountPath: /config

  containers:
  - name: main-app
    image: myapp:latest
    volumeMounts:
    - name: config-vol
      mountPath: /app/config

  volumes:
  - name: config-vol
    emptyDir: {}
```

**Execution flow:**
1. `wait-for-db` runs → waits until db-service is reachable
2. `init-config` runs → writes config file to shared volume
3. `main-app` starts → reads pre-populated config file

## Init Container vs Sidecar

| Feature | Init Container | Sidecar |
|---|---|---|
| When it runs | Before main containers | Alongside main containers |
| Duration | Runs to completion | Runs for Pod lifetime |
| Purpose | Setup / preconditions | Supporting functionality |

## Key Commands

```bash
# Check init container status
kubectl get pod init-demo
# STATUS column shows: Init:0/2 (0 of 2 init containers done)

# Describe for detailed init status
kubectl describe pod init-demo
# Look for: Init Containers section

# Logs from init container (while running or after)
kubectl logs init-demo -c wait-for-db

# If init container already finished
kubectl logs init-demo -c init-config --previous
```

## Common Issues / Troubleshooting

- **Init:0/1** stuck → init container is running or failed; check its logs
- **CrashLoopBackOff on init container** → command failing; check logs
- **Init container completed but main app won't start** → volume mount issue or main container config error
- **Pod stuck in Init phase** → waiting for a service that never becomes available; check the wait condition

## Related Notes

- [[Pods]] — Init containers are defined in the Pod spec
- [[Multi-Container Pods]] — Sidecars run alongside main containers
- [[kubelet]] — Orchestrates init container execution sequence

## Key Mental Model

**Init Containers = preparation crew**. They show up before the show starts, set everything up, then leave. Main containers are the performers — ready to go because the groundwork is done. Essential for **reliable startup in complex Pods**.
