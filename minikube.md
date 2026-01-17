#cli 
# minikube
## Overview

**minikube** is a tool that runs a **single-node Kubernetes cluster locally**.
It is designed for:
- Learning Kubernetes
- Local development
- Testing manifests and workflows

minikube is **not production Kubernetes**. It is a controlled sandbox.

## What minikube Provides

A minikube cluster includes:
- [[kube-apiserver]]
- [[kube-controller-manager]]
- [[kube-scheduler]]
- [[kubelet]]
- [[etcd]]
- CNI networking

All components run on **one machine**.

## Architecture

- Single Node (control-plane + worker)
- Runs inside:
    - VM (VirtualBox, HyperKit, KVM)
    - Container (Docker driver)

Node roles are collapsed for simplicity.

## Installing minikube

Installation varies by OS. After installation, verify:

```bash
minikube version
```

## Starting a Cluster

```bash
minikube start
```

Specify driver:

```bash
minikube start --driver=docker
```

Specify Kubernetes version:

```bash
minikube start --kubernetes-version=v1.29.0
```

## Cluster Interaction

Configure kubectl context automatically:

```bash
kubectl get nodes
```

You should see a single Node in Ready state.

## Addons

minikube includes built-in addons:

```bash
minikube addons list
```

Enable an addon:

```bash
minikube addons enable metrics-server
```

Common addons:
- Dashboard
- Ingress
- Metrics Server
- Storage Provisioner

## Accessing Services

NodePort:

```bash
minikube service my-service
```

Get Service URL:

```bash
minikube service my-service --url
```

## Dashboard

Launch the Kubernetes dashboard:

```bash
minikube dashboard
```

## Storage in minikube

- Uses hostPath or built-in storage provisioner
- PersistentVolumes are local to the VM/container
- Data is not durable across cluster deletion

## Stopping and Deleting

Stop cluster:

```bash
minikube stop
```

Delete cluster:

```bash
minikube delete
```

## Limitations

- Single-node only
- No real HA
- Performance differs from production
- Networking behavior can differ slightly

## Best Use Cases

- CKA practice
- Manifest experimentation
- Controller behavior testing
- Learning scheduling concepts

## Key Mental Model

minikube is **Kubernetes in a terrarium**.

Everything behaves like Kubernetes —
but the environment is simplified, contained, and forgiving.
Perfect for learning. Unsafe for production.