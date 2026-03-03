---
tags: [cka/workloads, workloads]
aliases: [Pod, Kubernetes Pod]
---

# Pods

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[kubelet]], [[kube-scheduler]], [[Deployments]], [[Services]], [[ConfigMap]], [[Secrets]]

## Overview

A **Pod** is the smallest deployable unit in Kubernetes, representing **one or more tightly coupled containers** that share networking, storage, and lifecycle. Pods are **ephemeral** — they are meant to be replaced, not updated in place.

## Pod Anatomy

- **Containers**: One or more container images running together
- **Shared Networking**: Single IP, shared port space, localhost communication between containers
- **Shared Storage**: Volumes mounted across all containers in the Pod
- **PodSpec**: Desired state (what you define)
- **PodStatus**: Current state (reported by [[kubelet]])

## Lifecycle Phases

| Phase | Meaning |
|---|---|
| Pending | Accepted but not yet running (scheduling or image pull) |
| ContainerCreating | Containers being initialized |
| Running | At least one container running |
| Succeeded | All containers completed successfully (Jobs) |
| Failed | At least one container exited with error |
| Unknown | Node unreachable; state unknown |

## Basic Pod Definition

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: web
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
    env:
    - name: ENV_VAR
      value: "value"
  restartPolicy: Always   # Always | OnFailure | Never
```

## Health Probes

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5

startupProbe:
  httpGet:
    path: /healthz
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

- **Liveness** → restarts unhealthy containers
- **Readiness** → controls [[Services]] endpoint inclusion (Pod won't receive traffic until ready)
- **Startup** → delays liveness for slow-starting containers

## Volumes in Pods

```yaml
spec:
  volumes:
  - name: config-vol
    configMap:
      name: my-config
  - name: secret-vol
    secret:
      secretName: my-secret
  - name: data
    emptyDir: {}
  - name: storage
    persistentVolumeClaim:
      claimName: my-pvc

  containers:
  - name: app
    volumeMounts:
    - name: config-vol
      mountPath: /etc/config
    - name: data
      mountPath: /data
```

## Key Commands

```bash
# Create pod
kubectl run nginx --image=nginx

# Get pod details
kubectl get pod nginx -o wide
kubectl describe pod nginx

# View logs
kubectl logs nginx
kubectl logs nginx --previous        # Crashed container
kubectl logs nginx -c <container>    # Specific container

# Exec into pod
kubectl exec -it nginx -- /bin/sh

# Delete pod
kubectl delete pod nginx

# Force delete (if stuck terminating)
kubectl delete pod nginx --force --grace-period=0
```

## Common Issues / Troubleshooting

- **Pending** → scheduling failure: check resources, taints, nodeSelector; `kubectl describe pod`
- **CrashLoopBackOff** → container keeps crashing; `kubectl logs --previous` for crash reason
- **ImagePullBackOff** → wrong image name/tag or missing pull secret
- **OOMKilled** → memory limit too low; increase limits
- **Terminating stuck** → finalizers blocking; use `--force --grace-period=0`
- **Init container stuck** → check init container logs: `kubectl logs nginx -c init-container-name`

## Related Notes

- [[kubelet]] — Runs and monitors pods on the node
- [[kube-scheduler]] — Assigns pods to nodes
- [[Deployments]] — Manages pods at scale with rolling updates
- [[Init Containers]] — Containers that run before main containers
- [[Multi-Container Pods]] — Sidecar patterns
- [[Pod Troubleshooting]] — Full diagnosis workflow

## Key Mental Model

A Pod is a **temporary home** for containers. It provides them with shared identity (IP), shared storage (volumes), and shared fate (lifecycle). When the home is destroyed, the containers go with it — which is why [[Deployments]] exist to rebuild them.
