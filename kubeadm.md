# kubeadm
## Overview

**kubeadm** is a Kubernetes tool that **bootstraps a cluster** in a standardized and opinionated way.

It handles:
- Control plane initialization
- Node joining
- Certificate management
- Core component configuration

kubeadm focuses on **cluster lifecycle**, not day-to-day operations.

## What kubeadm Does

- Initializes the **control plane**
- Generates TLS certificates
- Creates static Pod manifests
- Configures kubelet
- Bootstraps core components

🔗 Related:
- [[kube-apiserver]]
- [[kube-controller-manager]]
- [[kube-scheduler]]
- [[etcd]]
- [[kubelet]]

## What kubeadm Does NOT Do

- Install networking (CNI)
- Manage workloads
- Upgrade OS packages
- Provide cluster UI

These are **explicitly left to the user**.

## Control Plane Initialization

```bash
kubeadm init
```

Common flags:

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16
```

This command:
- Creates /etc/kubernetes/manifests/*
- Starts control plane as **static Pods**
- Outputs kubeadm join command

🔗 Related:
- [[Static Pods]]
- [[Manifests]]

## Configure kubectl (After Init)

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## **Joining Worker Nodes**

```bash
kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>
```

Tokens expire by default.

Create a new token:

```bash
kubeadm token create --print-join-command
```

## Installing a CNI Plugin

kubeadm **requires** a CNI plugin.

Examples:
- Calico
- Flannel
- Weave

Without CNI:
- Pods remain in Pending state

## Cluster Status Check

```bash
kubectl get nodes
kubectl get pods -n kube-system
```

## kubeadm Upgrades

kubeadm manages **Kubernetes version upgrades**, not OS upgrades.

```bash
kubeadm upgrade plan
kubeadm upgrade apply v1.29.0
```

🔗 Related:
- [[OS Upgrade]]

## Resetting a Node

```bash
kubeadm reset
```

Removes cluster configuration but **does not delete CNI files**.

## Best Practices

- Use kubeadm for learning and CKA prep
- Always install CNI immediately
- Back up /etc/kubernetes
- Upgrade control plane before workers
- Automate where possible

## Key Mental Model

kubeadm is the **midwife of Kubernetes clusters**.

It doesn’t raise the cluster or manage its life —
it just ensures the birth is **clean, secure, and repeatable**.