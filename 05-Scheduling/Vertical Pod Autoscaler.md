---
tags: [cka/workloads, workloads]
aliases: [VPA, Vertical Autoscaler]
---

# Vertical Pod Autoscaler

> **Exam Domain**: Workloads & Scheduling (15%)
> **Related**: [[Autoscaling]], [[Resource Limits]], [[Pods]], [[Deployments]]

## Overview

The **Vertical Pod Autoscaler (VPA)** automatically adjusts **CPU and memory requests (and optionally limits)** for [[Pods]] based on actual usage. Instead of adding more Pods (like HPA), VPA makes **existing Pods bigger or smaller**.

## VPA vs HPA

| Feature | VPA | HPA |
|---|---|---|
| What it adjusts | Resource requests/limits | Replica count |
| Scaling direction | Vertical (bigger/smaller) | Horizontal (more/fewer) |
| Pod restarts | Yes (to apply new values) | No |
| Best for | Unpredictable resource needs | Variable load patterns |

> [!warning]
> Using VPA and HPA together for the same CPU/memory metric can cause instability — they will fight each other.

## VPA Components (Not Installed by Default)

VPA must be installed separately:
- **Recommender** — monitors usage and generates recommendations
- **Updater** — evicts Pods that need resource changes
- **Admission Controller** — applies recommendations to new Pods

## VPA Modes

| Mode | Behavior |
|---|---|
| `Off` | Recommendations generated only (no changes) |
| `Initial` | Applied at Pod creation only |
| `Auto` | Applied during runtime (may restart Pods) |

## VPA Example

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web
  updatePolicy:
    updateMode: "Auto"   # Off | Initial | Auto
  resourcePolicy:
    containerPolicies:
    - containerName: "*"
      minAllowed:
        cpu: 100m
        memory: 50Mi
      maxAllowed:
        cpu: 1
        memory: 500Mi
```

## Key Commands

```bash
# Check VPA recommendations
kubectl get vpa
kubectl describe vpa web-vpa

# Look for recommendations section in describe output
# Shows: Lower Bound, Upper Bound, Target, Uncapped Target
```

## Common Issues / Troubleshooting

- **Unexpected Pod restarts** → VPA in Auto mode evicting Pods to apply new values
- **VPA and HPA conflict** → both reacting to CPU metrics; use HPA for CPU scaling, VPA for memory only
- **Recommendations too high/low** → set `minAllowed`/`maxAllowed` bounds in containerPolicies
- **VPA not working** → check if VPA components are installed: `kubectl get pods -n kube-system | grep vpa`

## Related Notes

- [[Autoscaling]] — HPA, VPA, and Cluster Autoscaler overview
- [[Resource Limits]] — VPA adjusts these automatically
- [[Deployments]] — Primary VPA target
- [[Pods]] — VPA may restart pods to apply new resources

## Key Mental Model

VPA is a **tailor, not a crowd manager**. HPA hires more workers (pods). VPA resizes their desks (resources). Used correctly, VPA reduces waste and prevents starvation — but it always comes with the cost of **restarts**.
