---
tags: [cka/architecture, configuration, workloads]
aliases: [Resource Requests, Limits, CPU Limits, Memory Limits, OOMKilled]
---

# Resource Limits

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Pods]], [[Scheduling]], [[kube-scheduler]], [[Autoscaling]], [[Namespaces]]

## Overview

**Resource Requests and Limits** control how much CPU and memory a container can use. **Requests** are used by [[kube-scheduler]] to decide where to place a Pod. **Limits** are enforced at runtime by the [[kubelet]] and the Linux kernel — they cap actual usage.

## Requests vs Limits

| | Requests | Limits |
|---|---|---|
| Used for | Scheduling decisions | Runtime enforcement |
| Effect if exceeded | Not scheduled | CPU throttled / OOMKilled |
| Required? | Recommended | Optional |
| Who enforces | kube-scheduler | kubelet + kernel cgroups |

## Defining Resources

```yaml
spec:
  containers:
  - name: app
    image: myapp:latest
    resources:
      requests:
        cpu: "250m"       # 0.25 cores guaranteed
        memory: "128Mi"   # 128 MiB guaranteed
      limits:
        cpu: "500m"       # 0.5 cores max
        memory: "256Mi"   # 256 MiB max — OOMKill above this
```

## CPU Units

| Notation | Meaning |
|---|---|
| `1` | 1 full CPU core |
| `500m` | 500 millicores = 0.5 cores |
| `100m` | 100 millicores = 0.1 cores |

CPU is **compressible**: if a container exceeds its CPU limit, it is **throttled** (slowed down) but NOT killed.

## Memory Units

| Notation | Meaning |
|---|---|
| `128Mi` | 128 mebibytes |
| `1Gi` | 1 gibibyte |
| `512M` | 512 megabytes (decimal) |

Memory is **NOT compressible**: if a container exceeds its memory limit, it is **OOMKilled** (process terminated immediately).

## QoS Classes

Kubernetes assigns a Quality of Service class based on requests/limits:

| QoS Class | Condition | Eviction Priority |
|---|---|---|
| `Guaranteed` | Requests = Limits (both set) | Last to be evicted |
| `Burstable` | Requests < Limits | Middle priority |
| `BestEffort` | No requests or limits | First to be evicted |

## LimitRange (Namespace Defaults)

Set default requests/limits for all Pods in a namespace:

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: dev
spec:
  limits:
  - type: Container
    default:
      cpu: "500m"
      memory: "256Mi"
    defaultRequest:
      cpu: "100m"
      memory: "128Mi"
    max:
      cpu: "2"
      memory: "2Gi"
```

## ResourceQuota (Namespace Totals)

Cap total resources consumed by all Pods in a namespace:

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    pods: "20"
```

## Key Commands

```bash
# Check node allocatable resources
kubectl describe node <node> | grep -A5 "Allocatable"

# Check pod resource usage (requires metrics-server)
kubectl top pods
kubectl top pods --containers
kubectl top nodes

# Check if pod was OOMKilled
kubectl describe pod <pod>
# Look for: Last State: Terminated, Reason: OOMKilled

# Check ResourceQuota usage
kubectl describe resourcequota -n dev

# Check LimitRange
kubectl describe limitrange -n dev
```

## Common Issues / Troubleshooting

- **OOMKilled** → memory limit too low; increase `limits.memory` or fix memory leak in app
- **CPU throttling** → container running slow due to CPU limit; increase `limits.cpu`
- **Pod stuck Pending** → requests exceed any Node's available resources; check `kubectl describe pod`
- **ResourceQuota exceeded** → namespace has used all allowed resources; `kubectl describe resourcequota`
- **No requests set + HPA** → [[Autoscaling|HPA]] can't calculate utilization percentage; always set CPU requests

## Related Notes

- [[Pods]] — Where resource requests and limits are defined
- [[Scheduling]] — kube-scheduler uses requests for placement
- [[Autoscaling]] — HPA requires CPU requests to calculate utilization
- [[Namespaces]] — LimitRange and ResourceQuota scope to namespaces
- [[Vertical Pod Autoscaler]] — Automatically tunes requests and limits

## Key Mental Model

**Requests decide where a Pod runs. Limits decide how much it can consume once it's there.** Requests are promises to the scheduler. Limits are circuit breakers enforced by the kernel. Set both — the scheduler needs to plan, and the node needs protection.
