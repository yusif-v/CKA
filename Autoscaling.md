# Autoscaling

## Overview

**Autoscaling** in Kubernetes automatically adjusts resources based on demand.
Kubernetes supports autoscaling at **three levels**:

- **Pod level** (HPA)
- **Node level** (Cluster Autoscaler)
- **Resource level** (VPA)

Autoscaling keeps applications **responsive**, **cost-efficient**, and **stable under load**.

## [[Horizontal Pod Autoscaler]] (HPA)
### What it does

Scales the **number of Pods** based on metrics.

Most commonly:
- CPU utilization
- Memory utilization
- Custom or external metrics

Works with:
- [[Deployment]]
- [[ReplicaSet]]
- [[StatefulSet]]

### HPA Example

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

HPA **requires resource requests** to be set on containers.

🔗 Related:
- [[Resource Requests]]
- [[metrics-server]]

### Create HPA Imperatively

```
kubectl autoscale deployment web --min=2 --max=10 --cpu-percent=50
```

## [[Vertical Pod Autoscaler]] (VPA)

### What it does

Automatically adjusts **CPU and memory requests/limits** for Pods.

Modes:
- Off – recommendations only
- Initial – applies at Pod creation
- Auto – updates during runtime (restarts Pods)
 
🔗 Related:
- [[Resource Limits]]
- [[Resource Requests]]

## Cluster Autoscaler
### What it does

Scales the **number of Nodes** in the cluster.
- Adds nodes when Pods are **unschedulable**
- Removes nodes when underutilized
- Works with cloud providers (GKE, EKS, AKS, etc.)

🔗 Related:
- [[Scheduling]]
- [[Node Affinity]]
- [[Taints]]
- [[Tolerations]]

## Metrics Source

Autoscaling depends on metrics provided by:
- **metrics-server** (CPU & memory)
- Prometheus (custom metrics)
- External metrics providers

```bash
kubectl top pods
kubectl top nodes
```

## Autoscaling Flow (Mental Model)

1. Metrics collected
2. Autoscaler evaluates thresholds
3. Kubernetes adjusts Pods or Nodes
4. Scheduler places Pods accordingly

Autoscaling is **reactive control theory applied to infrastructure**.

## Best Practices

- Always define **resource requests**
- Set realistic min/max replicas
- Avoid aggressive scaling thresholds
- Monitor scaling behavior over time
- Combine HPA with Cluster Autoscaler for full elasticity

## Key Mental Model

Autoscaling is Kubernetes **breathing**:
- Inhale → scale up
- Exhale → scale down

The cluster adapts continuously, as long as you give it **metrics, limits, and clear intent**.