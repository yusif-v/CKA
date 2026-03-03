---
tags: [cka/architecture, architecture, cli]
aliases: [kubeadm init, kubeadm join, cluster bootstrap]
---

# kubeadm

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[etcd]], [[kubelet]], [[Static Pods]], [[Kubeconfig]]

## Overview

**kubeadm** is a Kubernetes tool that **bootstraps a cluster** in a standardized way. It handles control plane initialization, node joining, certificate management, and core component configuration. kubeadm focuses on **cluster lifecycle**, not day-to-day operations.

> [!tip] Exam Tip
> Static Pod manifests are created at `/etc/kubernetes/manifests/` — know this path.
> After `kubeadm init`, always run the kubectl config commands to access the cluster.

## What kubeadm Does

- Initializes the control plane
- Generates TLS certificates in `/etc/kubernetes/pki/`
- Creates [[Static Pods]] manifests for control plane components
- Configures [[kubelet]]
- Creates [[Kubeconfig]] files for cluster access

## What kubeadm Does NOT Do

- Install networking (CNI) — you must install this separately
- Manage workloads
- Upgrade OS packages
- Provide cluster UI

## Control Plane Initialization

```bash
# Basic init
kubeadm init

# With pod network CIDR (required for most CNI plugins)
kubeadm init --pod-network-cidr=10.244.0.0/16

# With specific API server address
kubeadm init --apiserver-advertise-address=<node-ip> \
             --pod-network-cidr=10.244.0.0/16
```

After init, configure kubectl access:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Joining Worker Nodes

```bash
# Use the join command output from kubeadm init
kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# Regenerate join command if token expired
kubeadm token create --print-join-command
```

## Installing a CNI Plugin

kubeadm **requires** a CNI plugin — without one, Pods stay Pending:

```bash
# Flannel example
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Calico example
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## Kubernetes Version Upgrades

```bash
# Check available upgrade
kubeadm upgrade plan

# Apply upgrade
kubeadm upgrade apply v1.30.0

# Upgrade kubelet and kubectl after (OS package manager)
```

## Certificate Management

```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all
```

## Resetting a Node

```bash
# Remove cluster configuration (does NOT delete CNI files)
kubeadm reset

# Also clean up CNI manually
rm -rf /etc/cni/net.d
```

## Key Commands

```bash
# Initialize cluster
kubeadm init --pod-network-cidr=10.244.0.0/16

# Get join command
kubeadm token create --print-join-command

# Check cert expiry
kubeadm certs check-expiration

# Upgrade
kubeadm upgrade plan
kubeadm upgrade apply v1.30.0

# Reset
kubeadm reset
```

## Common Issues / Troubleshooting

- **Pods stuck Pending after init** → CNI not installed; `kubectl apply` a CNI manifest
- **Node can't join** → token expired; regenerate with `kubeadm token create --print-join-command`
- **kubectl connection refused** → forgot to copy admin.conf to `~/.kube/config`
- **Certificate errors** → run `kubeadm certs check-expiration`; renew if expired

## Related Notes

- [[Static Pods]] — kubeadm creates these to run the control plane
- [[Kubeconfig]] — kubeadm generates the admin kubeconfig
- [[etcd]] — kubeadm configures and bootstraps etcd
- [[TLS in Kubernetes]] — kubeadm manages all cluster certificates
- [[OS Upgrade]] — kubeadm handles k8s version upgrades

## Key Mental Model

kubeadm is the **midwife of Kubernetes clusters**. It doesn't raise the cluster or manage its life — it ensures the birth is **clean, secure, and repeatable**. After init, your job begins.
