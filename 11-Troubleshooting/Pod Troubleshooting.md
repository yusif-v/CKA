---
tags: [cka/troubleshooting, troubleshooting]
aliases: [Pod Debug, CrashLoopBackOff, ImagePullBackOff, OOMKilled]
---

# Pod Troubleshooting

> **Exam Domain**: Troubleshooting (30%)
> **Related**: [[Troubleshooting Guide]], [[Pods]], [[kubelet]], [[Services]], [[ConfigMap]], [[Secrets]]

## Overview

Pod troubleshooting covers diagnosing why [[Pods]] fail to start, keep crashing, or don't function as expected. The **Events section** of `kubectl describe pod` and `kubectl logs` resolve the vast majority of pod issues.

## Pod Status Reference

| Status | Meaning | Where to Look |
|---|---|---|
| `Pending` | Not scheduled yet | `describe pod` → scheduling Events |
| `ContainerCreating` | Containers being created | `describe pod` → image/volume Events |
| `Running` | At least one container running | `logs` → app errors |
| `CrashLoopBackOff` | Container crashes repeatedly | `logs --previous` |
| `ImagePullBackOff` | Can't pull container image | `describe pod` → Events |
| `ErrImagePull` | Image pull failed (first attempt) | `describe pod` → Events |
| `OOMKilled` | Killed by kernel — out of memory | `describe pod` → Last State |
| `Terminating` | Being deleted | Check finalizers |
| `CreateContainerConfigError` | Missing ConfigMap or Secret | `describe pod` → Events |
| `Init:0/1` | Init container not complete | `logs -c <init-container>` |

## Step-by-Step Pod Diagnosis

### Step 1: Get Basic Status

```bash
kubectl get pod <pod> -n <namespace>
kubectl get pod <pod> -n <namespace> -o wide   # Shows node assignment
```

### Step 2: Describe for Events (Most Important)

```bash
kubectl describe pod <pod> -n <namespace>
```

Always scroll to the **Events** section at the bottom — it contains the root cause for most failures:

```
Events:
  Type     Reason            Age   Message
  ----     ------            ----  -------
  Warning  FailedScheduling  2m    0/3 nodes are available: insufficient cpu
  Warning  Failed            1m    Error: ErrImagePull
  Normal   Pulling           30s   Pulling image "nginx:bad-tag"
```

### Step 3: Check Logs

```bash
# Current container logs
kubectl logs <pod> -n <namespace>

# Previous container logs (after crash)
kubectl logs <pod> -n <namespace> --previous

# Specific container in multi-container pod
kubectl logs <pod> -n <namespace> -c <container-name>

# Stream logs
kubectl logs <pod> -n <namespace> -f

# Last N lines
kubectl logs <pod> -n <namespace> --tail=50
```

### Step 4: Exec Into Running Container

```bash
kubectl exec -it <pod> -n <namespace> -- /bin/sh
kubectl exec -it <pod> -n <namespace> -- /bin/bash

# Specific container
kubectl exec -it <pod> -n <namespace> -c <container> -- /bin/sh

# Single command
kubectl exec <pod> -n <namespace> -- env
kubectl exec <pod> -n <namespace> -- cat /etc/config/settings
```

## Diagnosing by Status

### Pending Pod

```bash
kubectl describe pod <pod>
# Events will show one of:
# - "0/3 nodes available: insufficient cpu/memory"
# - "0/3 nodes available: node(s) had taint"
# - "0/3 nodes available: node(s) didn't match nodeSelector"
```

Fixes:
- **Resource issue** → reduce `requests` or add nodes
- **Taint** → add toleration or remove taint
- **nodeSelector** → fix label on node or remove selector
- **PVC not bound** → check `kubectl get pvc`

### CrashLoopBackOff

```bash
# View crash reason
kubectl logs <pod> --previous

# Check restart count
kubectl get pod <pod> -o wide    # RESTARTS column

# Describe for exit code and reason
kubectl describe pod <pod>
# Look for: Last State: Terminated, Exit Code: 1, Reason: Error
```

Common causes:
- App failing to start (config error, missing env var)
- Liveness probe failing → container restarted
- Application bug or missing dependency

### ImagePullBackOff / ErrImagePull

```bash
kubectl describe pod <pod>
# Events show: Failed to pull image "registry/image:tag": ...
```

Fixes:
- **Wrong image name/tag** → fix `image:` in pod spec
- **Private registry** → add `imagePullSecrets`
- **Registry unreachable** → check network policy / firewall
- **Rate limiting** → Docker Hub rate limit; add credentials

### OOMKilled

```bash
kubectl describe pod <pod>
# Last State: Terminated
# Reason: OOMKilled
# Exit Code: 137
```

Fixes:
- Increase `limits.memory`
- Fix memory leak in application
- Profile application memory usage

### CreateContainerConfigError

```bash
kubectl describe pod <pod>
# Events: Error: secret "db-secret" not found
# Or: configmap "app-config" not found
```

Fixes:
- Create the missing [[ConfigMap]] or [[Secrets]]
- Check namespace — resource must be in same namespace

### Init:0/1 (Init Container Failing)

```bash
# Check init container logs
kubectl logs <pod> -c <init-container-name>

# Describe shows init container status
kubectl describe pod <pod>
# Look for: Init Containers section
```

## Temporary Debug Pod

Spin up a debug container to test networking and DNS from within the cluster:

```bash
# BusyBox for basic testing
kubectl run debug --image=busybox --rm -it -- /bin/sh

# Test DNS
nslookup <service-name>
nslookup <service-name>.<namespace>.svc.cluster.local

# Test HTTP
wget -qO- http://<service>:<port>
wget -qO- http://<service>.<namespace>:80

# Test TCP connectivity
nc -zv <service> <port>

# Curl (if available)
kubectl run debug --image=curlimages/curl --rm -it -- sh
curl http://<service>:<port>
```

## Service Endpoint Verification

A common exam task — verify a Service is routing to the right Pods:

```bash
# Check service definition
kubectl describe svc <service> -n <namespace>
# Look for: Selector field

# Check what pods match that selector
kubectl get pods -l <selector-label>=<value> -n <namespace>

# Check endpoints (should show pod IPs)
kubectl get endpoints <service> -n <namespace>
# Empty endpoints = selector mismatch!
```

## Key Commands Summary

```bash
# Core diagnostic trio
kubectl get pod <pod>
kubectl describe pod <pod>
kubectl logs <pod> [--previous] [-c <container>]

# Active debugging
kubectl exec -it <pod> -- /bin/sh
kubectl run debug --image=busybox --rm -it -- sh

# Service verification
kubectl get endpoints <svc>
kubectl describe svc <svc>

# Events (pod-specific)
kubectl get events --field-selector involvedObject.name=<pod>
```

## Common Issues Quick Reference

| Status | Cause | Fix |
|---|---|---|
| `Pending` | No schedulable node | Check resources, taints, selectors |
| `CrashLoopBackOff` | App crashing | `logs --previous` |
| `ImagePullBackOff` | Image or auth issue | Check image name, add pull secret |
| `OOMKilled` | Memory limit exceeded | Increase `limits.memory` |
| `CreateContainerConfigError` | Missing ConfigMap/Secret | Create the resource |
| `Init:0/1` | Init container failing | `logs -c <init-container>` |
| Running but broken | App logic error | `logs` and `exec` to investigate |

## Related Notes

- [[Troubleshooting Guide]] — Master diagnostic workflow
- [[Pods]] — Pod lifecycle and spec reference
- [[Node Troubleshooting]] — When node itself is the problem
- [[Services]] — Endpoint verification for connectivity issues
- [[ConfigMap]] / [[Secrets]] — CreateContainerConfigError fixes

## Key Mental Model

Pod troubleshooting is a **funnel**: start wide (`kubectl get pods`), get narrower (`kubectl describe pod` → Events), then go deep (`kubectl logs --previous` → app output). The Events section is your **first stop** — it gives you the reason in plain English. Logs give you the **detail**. Exec gives you the **ability to probe**.
