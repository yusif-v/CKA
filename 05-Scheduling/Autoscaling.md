---
tags: [cka/workloads, workloads]
aliases: [HPA, Horizontal Pod Autoscaler, Cluster Autoscaler]
---

# Autoscaling

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Vertical Pod Autoscaler]], [[Deployments]], [[Scheduling]], [[Resource Limits]]

## Overview

**Autoscaling** in Kubernetes automatically adjusts resources based on demand at three levels: **Pod count** (HPA), **Node count** (Cluster Autoscaler), and **Pod resource sizing** (VPA). Autoscaling keeps applications responsive, cost-efficient, and stable under load.

> [!tip] Exam Tip
> HPA requires `resource requests` to be set on containers and `metrics-server` to be installed.

## Horizontal Pod Autoscaler (HPA)

Scales the **number of [[Pods]]** based on metrics:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
```

### Create HPA Imperatively

```bash
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=50
```

### HPA Requirements

- `metrics-server` must be installed
- Target resource must have CPU **requests** defined
- Works with [[Deployments]], ReplicaSets, StatefulSets

## Vertical Pod Autoscaler (VPA)

See [[Vertical Pod Autoscaler]] for full details. Adjusts CPU and memory **requests/limits** rather than replica count.

## Cluster Autoscaler

Scales the **number of Nodes**:
- Adds nodes when [[Pods]] are unschedulable due to resource constraints
- Removes nodes when they are underutilized
- Cloud-provider specific (GKE, EKS, AKS, etc.)

## Metrics Sources

Autoscaling depends on:
- **metrics-server** → CPU and memory (built-in)
- **Prometheus adapter** → custom application metrics
- **External metrics providers** → queue depth, request rate

```bash
# Check if metrics-server is working
kubectl top pods
kubectl top nodes
```

## Key Commands

```bash
# Create HPA imperatively
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=50

# View HPA status
kubectl get hpa
kubectl describe hpa web-hpa

# Check current metrics
kubectl top pods
kubectl top nodes

# Delete HPA
kubectl delete hpa web-hpa
```

## Common Issues / Troubleshooting

- **HPA shows `<unknown>` metrics** → metrics-server not installed or Pod has no resource requests
- **HPA not scaling up** → check `kubectl describe hpa` for events; verify metrics are flowing
- **HPA scaling too aggressively** → adjust `stabilizationWindowSeconds` in behavior spec
- **VPA and HPA conflict** → don't use both for CPU metrics simultaneously

## Related Notes

- [[Vertical Pod Autoscaler]] — Per-pod resource sizing
- [[Deployments]] — Primary target for HPA
- [[Scheduling]] — Cluster Autoscaler interacts with scheduler
- [[Resource Limits]] — Requests must be set for HPA to work

## Key Mental Model

Autoscaling is Kubernetes **breathing**: inhale when load increases (scale up), exhale when load drops (scale down). The cluster adapts continuously — as long as you give it **metrics, limits, and clear intent**.
