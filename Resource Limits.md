#resource 
# Resource Limits
## Overview

**Resource Limits** define the **maximum amount of CPU and memory** a container is allowed to use at runtime.
Limits are enforced by the **container runtime and the kernel**, not by the scheduler.
Scheduling decisions are made using [[Resource Requests]].
Limits exist to protect the **Node** from resource exhaustion handled by the [[kubelet]].

## What Resource Limits Control

Resource Limits affect:
- CPU usage (throttling)
- Memory usage (OOM termination)
- Runtime behavior of containers inside a [[Pod]]

They do **not** influence placement decisions made during [[Scheduling]].

## Defining Resource Limits

```yaml
resources:
  limits:
    cpu: "1"
    memory: "512Mi"
```

CPU units:

- 1 = one core
- 500m = half a core

Memory units use binary suffixes (Mi, Gi).

## CPU Limits

CPU is a **compressible** resource.
When a container exceeds its CPU limit:
- It is **throttled**
- It continues running
- Requests are delayed, not killed

CPU limits are enforced via **cgroups** by the [[kubelet]].

## Memory Limits

Memory is **not compressible**.
When a container exceeds its memory limit:
- It is **OOMKilled**
- The container is terminated
- The Pod may restart depending on its restart policy

To diagnose:

```bash
kubectl describe pod <pod-name>
```

Look for:

```bash
Reason: OOMKilled
```

## Limits Without Requests

If a limit is defined without a request:
- Kubernetes sets the request equal to the limit
- Scheduler assumes full resource usage


This behavior is explained in [[Requests vs Limits]] and often leads to inefficient bin-packing.

## Requests Without Limits

Containers may define requests without limits:
- Scheduler allows placement
- Runtime usage is unbounded

This is usually restricted using [[LimitRange]] at the [[Namespace]] level.

## Namespace-Level Enforcement

Default and maximum limits can be enforced per namespace using [[LimitRange]].
Hard caps across all workloads in a namespace are enforced using [[ResourceQuota]].

## Resource Limits vs Scheduling

The scheduler considers only [[Resource Requests]].
Limits are enforced **after** the Pod is running on a Node.

Placement logic belongs to [[Scheduling]] and is executed by the [[kube-scheduler]].

## Observing Runtime Impact

To inspect live resource usage:

```bash
kubectl top pod
kubectl top node
```

This requires metrics-server to be installed.

## Key Mental Model

Resource Limits are:
- Runtime safety rails
- Enforced at the Node level
- Independent from scheduling  

**Requests decide where a Pod runs.**
**Limits decide how much it can consume once it’s there.**