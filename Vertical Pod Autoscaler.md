# Vertical Pod Autoscaler
## Overview

The **Vertical Pod Autoscaler (VPA)** automatically adjusts **CPU and memory requests (and optionally limits)** for Pods based on actual usage.

Instead of adding more Pods, VPA makes **existing Pods bigger or smaller**.

## What VPA Scales

- CPU **requests**
- Memory **requests**
- (Optionally) CPU & memory **limits**

VPA does **not** change the number of Pods.

🔗 Related:
- [[Resource Requests]]
- [[Resource Limits]]

## How VPA Works

1. VPA monitors historical resource usage
2. Generates recommendations
3. Applies changes depending on mode
4. Pods may be **restarted** to apply new values

## VPA Modes

- **Off** → Recommendations only
- **Initial** → Applied at Pod creation
- **Auto** → Applied during runtime (Pod restarts)

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
    updateMode: Auto
```

## Observing VPA

```bash
kubectl describe vpa web-vpa
```

Check recommendations:

```bash
kubectl get vpa
```

## VPA and HPA Together

- VPA **changes size**
- HPA **changes count**

Using both together is **not recommended** unless carefully configured.

Reason: Both react to CPU metrics, causing unstable scaling.

## Installation Notes

VPA is **not installed by default**.

Components:
- Recommender
- Updater
- Admission Controller

Usually installed via manifests.

## Best Practices

- Start with Off mode to observe recommendations
- Use Initial mode for predictable workloads
- Avoid Auto for latency-sensitive apps
- Set resource limits carefully
- Monitor Pod restarts

## Common Pitfalls

- Unexpected Pod restarts
- Conflicts with HPA
- Limits set too low
- Stateful workloads scaling unpredictably

## Key Mental Model

VPA is a **tailor, not a crowd manager**.
- HPA hires more workers
- VPA resizes their desks

Used correctly, VPA reduces waste and prevents starvation — but it always comes with the cost of **restarts**.