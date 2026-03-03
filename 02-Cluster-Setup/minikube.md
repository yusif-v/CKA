---
tags: [cka/architecture, cli]
aliases: [local cluster, minikube cluster]
---

# minikube

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubeadm]], [[kubectl]], [[Kubeconfig]]

## Overview

**minikube** runs a **single-node Kubernetes cluster locally**. It is designed for learning, local development, and testing manifests. minikube is **not production Kubernetes** — it is a controlled sandbox where all control plane and worker node components collapse onto one machine.

## What minikube Provides

A complete Kubernetes cluster including:
- [[kube-apiserver]]
- [[kube-controller-manager]]
- [[kube-scheduler]]
- [[kubelet]]
- [[etcd]]
- CNI networking
- Storage provisioner

## Architecture

- Single Node acting as both control-plane and worker
- Runs inside a VM (VirtualBox, HyperKit, KVM) or container (Docker driver)
- `kubectl` context is configured automatically on start

## Key Commands

```bash
# Start cluster
minikube start

# Start with specific driver
minikube start --driver=docker

# Start with specific Kubernetes version
minikube start --kubernetes-version=v1.30.0

# Check status
minikube status

# Stop cluster
minikube stop

# Delete cluster
minikube delete

# SSH into minikube node
minikube ssh
```

## Addons

```bash
# List available addons
minikube addons list

# Enable an addon
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable dashboard
```

## Accessing Services

```bash
# Open service in browser
minikube service my-service

# Get service URL
minikube service my-service --url

# Launch Kubernetes dashboard
minikube dashboard
```

## Storage in minikube

- Uses hostPath or built-in storage provisioner
- [[Persistent Volumes]] are local to the VM/container
- Data is NOT durable across cluster deletion

## Limitations

- Single-node only (no real HA)
- Performance differs from production
- Networking behavior can differ slightly
- Not suitable for multi-node testing (use `kind` for that)

## Common Issues / Troubleshooting

- **Start fails** → check driver is installed; try `minikube start --driver=docker`
- **kubectl not connecting** → run `minikube update-context`
- **Addon not working** → check `minikube addons list` for status
- **Out of disk space** → `minikube delete` then `minikube start`

## Related Notes

- [[kubeadm]] — Production-grade cluster bootstrap
- [[kubectl]] — CLI that connects to minikube cluster
- [[Kubeconfig]] — minikube auto-configures your kubeconfig

## Key Mental Model

minikube is **Kubernetes in a terrarium**. Everything behaves like Kubernetes — but the environment is simplified, contained, and forgiving. Perfect for learning. Not for production.
