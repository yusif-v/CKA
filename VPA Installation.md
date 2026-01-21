# VPA Installation

## Overview

The **Vertical Pod Autoscaler (VPA)** is **not installed by default** in Kubernetes.

It must be deployed manually and consists of **three core components**:
- Recommender
- Updater
- Admission Controller

VPA works by observing historical usage and updating resource requests.

🔗 Related:
- [[Vertical Pod Autoscaler]]
- [[Resource Requests]]
- [[Resource Limits]]

## Prerequisites

- Kubernetes cluster running
- kubectl configured
- Metrics available (usually via [[metrics-server]])
- Cluster-admin permissions

## Install VPA (Official Manifests)

Clone the autoscaler repository:

```bash
git clone https://github.com/kubernetes/autoscaler.git
```

Navigate to VPA directory:

```bash
cd autoscaler/vertical-pod-autoscaler
```

Run the installation script:

```bash
./hack/vpa-up.sh
```

This deploys:
- VPA Recommender
- VPA Updater
- VPA Admission Controller

All components run in the kube-system namespace.

## Verify Installation

Check VPA Pods:

```bash
kubectl get pods -n kube-system | grep vpa
```

Check CRDs:

```bash
kubectl get crd | grep verticalpodautoscaler
```

Expected CRDs:

- verticalpodautoscalers.autoscaling.k8s.io

## Verify API Availability

```bash
kubectl api-resources | grep VerticalPodAutoscaler
```

If listed, the API is active.

## Basic Test Deployment

Create a VPA object:

```bash
kubectl apply -f vpa.yaml
```

Check recommendations:

```bash
kubectl describe vpa <vpa-name>
```

## Uninstall VPA

From the same directory:

```
./hack/vpa-down.sh
```

## Key Mental Model

Installing VPA is like adding a **resource advisor** to the cluster.

It watches quietly, learns patterns, and only acts when you allow it to.
Powerful — but not something you install casually without understanding its consequences.