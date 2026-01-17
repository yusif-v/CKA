# metrics-server

## Overview

**metrics-server** is a cluster-wide aggregator of **resource usage metrics**.

It collects **CPU and memory usage** from Nodes and Pods and exposes them through the Kubernetes API.

metrics-server is required for:
- kubectl top
- [[Horizontal Pod Autoscaler]]

## What metrics-server Is (and Isn’t)

metrics-server:
- Provides **resource metrics**
- Uses a lightweight, short-term data store
- Focuses on current usage

metrics-server is **not**:
- A monitoring system
- A long-term metrics store
- A replacement for Prometheus

## Architecture

1. metrics-server queries [[kubelet]] on each Node
2. kubelet exposes metrics via the Summary API
3. metrics-server aggregates data
4. Data is exposed via the API server under metrics.k8s.io

## API Integration

Metrics are available through:

```bash
apis/metrics.k8s.io/v1beta1
```

Accessed transparently by kubectl and autoscalers.

## Installation

In managed clusters, metrics-server may be preinstalled.
In minikube:

```bash
minikube addons enable metrics-server
```

Manual installation uses a manifest provided by Kubernetes SIGs.

## Verification

Check if metrics-server is running:

```bash
kubectl get pods -n kube-system | grep metrics-server
```

Test metrics:

```bash
kubectl top nodes
kubectl top pods
```

## Resource Metrics Flow

- metrics-server polls metrics every few seconds
- Data is cached briefly
- Old data is discarded

This design keeps overhead low.

## Security Model

- Uses TLS to communicate with kubelet
- Requires access to kubelet APIs
- Often needs `--kubelet-insecure-tls` in local clusters

## Common Issues

- kubectl top returns no data
- TLS certificate errors
- kubelet unreachable
- metrics-server not authorized

Debugging often starts with logs:

```bash
kubectl logs -n kube-system metrics-server-<pod>
```

## Relationship to Autoscaling

metrics-server feeds:
- [[Horizontal Pod Autoscaler]]
- [[Vertical Pod Autoscaler]] (partial support)

Without it, autoscaling does not work.

## Performance Considerations

- Minimal resource footprint
- Designed for large clusters
- Avoids expensive storage operations

## Key Mental Model

metrics-server is **Kubernetes’ speedometer**.
It tells you how fast resources are being consumed **right now** —
not where you’ve been, and not where you’re going.

For history and analytics, you need heavier instruments.