---
tags: [cka/troubleshooting, troubleshooting]
aliases: [Node Debug, NotReady Node, kubelet troubleshooting]
---

# Node Troubleshooting

> **Exam Domain**: Troubleshooting (30%)
> **Related**: [[Troubleshooting Guide]], [[kubelet]], [[kube-proxy]], [[Static Pods]], [[Cluster Architecture]]

## Overview

Node troubleshooting covers diagnosing why a Node is `NotReady`, why Pods won't schedule on it, or why the [[kubelet]] is not functioning. Most node issues trace back to the kubelet service, networking, or resource pressure.

## Node Status Meanings

```bash
kubectl get nodes
```

| Status | Meaning |
|---|---|
| `Ready` | Node is healthy and schedulable |
| `NotReady` | Node has issues; Pods may be evicted |
| `SchedulingDisabled` | Node is cordoned (`kubectl cordon`) |
| `Unknown` | Node controller lost contact with node |

## Step-by-Step Node Diagnosis

### Step 1: Check Node Conditions

```bash
kubectl describe node <node-name>
```

Look for the **Conditions** section:

| Condition | False = Problem |
|---|---|
| `Ready` | Should be True — if False, check kubelet |
| `MemoryPressure` | Should be False — if True, node is low on memory |
| `DiskPressure` | Should be False — if True, disk is almost full |
| `PIDPressure` | Should be False — if True, too many processes |
| `NetworkUnavailable` | Should be False — if True, CNI issue |

### Step 2: Check kubelet on the Node

SSH into the node:

```bash
# Check kubelet service status
systemctl status kubelet

# Is it running? If not:
systemctl start kubelet
systemctl enable kubelet

# View kubelet logs (most important)
journalctl -u kubelet -f
journalctl -u kubelet -n 100 --no-pager
journalctl -u kubelet --since "10 minutes ago"
```

### Step 3: Check kubelet Configuration

```bash
# Find kubelet config
cat /var/lib/kubelet/config.yaml

# Check kubelet flags
ps aux | grep kubelet

# Common config issues:
# - Wrong --pod-manifest-path
# - Wrong --container-runtime-endpoint
# - Bad kubeconfig path
cat /etc/kubernetes/kubelet.conf
```

### Step 4: Check Container Runtime

```bash
# Check containerd
systemctl status containerd
crictl info

# List running containers
crictl ps

# Check if containerd is reachable
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps
```

### Step 5: Check Network

```bash
# Check CNI plugins installed
ls /etc/cni/net.d/
ls /opt/cni/bin/

# Check kube-proxy on this node
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Test node-to-node connectivity (from node)
ping <other-node-ip>
```

### Step 6: Check Resources

```bash
# Disk space
df -h

# Memory
free -m

# CPU load
top

# Resource pressure from Kubernetes perspective
kubectl describe node <node> | grep -A10 "Allocated resources"
```

## Static Pod Issues on Nodes

If control plane components (kube-apiserver, etcd, etc.) are down:

```bash
# Check static pod manifests exist
ls -la /etc/kubernetes/manifests/

# View manifest content
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Static pod not starting? Check kubelet logs
journalctl -u kubelet | grep "kube-apiserver"

# Force restart static pod by touching the manifest
touch /etc/kubernetes/manifests/kube-apiserver.yaml
```

## Node Disk Pressure

```bash
# Find what's consuming disk
du -sh /var/log/*
du -sh /var/lib/docker/*    # If using docker
du -sh /var/lib/containerd/*

# Clean up unused container images (on node)
crictl rmi --prune

# Check log rotation
journalctl --disk-usage
journalctl --vacuum-time=2d
```

## Node Memory Pressure

```bash
# Check memory usage
free -m
cat /proc/meminfo

# Find memory-heavy processes
ps aux --sort=-%mem | head -20

# Check for OOMKilled pods on this node
kubectl get pods --field-selector spec.nodeName=<node> -A | grep -v Running
```

## Key Commands Summary

```bash
# From kubectl (cluster-side)
kubectl get nodes
kubectl describe node <node>
kubectl get events --field-selector involvedObject.kind=Node

# From node (SSH required)
systemctl status kubelet
systemctl restart kubelet
journalctl -u kubelet -n 100
df -h
free -m
crictl ps
ls /etc/kubernetes/manifests/
```

## Common Issues and Fixes

| Issue | Diagnosis | Fix |
|---|---|---|
| Node `NotReady` | `systemctl status kubelet` | `systemctl restart kubelet` |
| kubelet won't start | `journalctl -u kubelet` | Fix config file syntax error |
| Disk pressure | `df -h` | Clean logs, old images, prune |
| Memory pressure | `free -m` | Kill or move memory-heavy pods |
| Static pods down | `ls /etc/kubernetes/manifests/` | Fix/replace manifest YAML |
| CNI issues | `ls /etc/cni/net.d/` | Reinstall CNI plugin |
| containerd down | `systemctl status containerd` | `systemctl restart containerd` |
| Certificate expired | `kubeadm certs check-expiration` | `kubeadm certs renew all` |

## Related Notes

- [[Troubleshooting Guide]] — Master workflow for all cluster issues
- [[kubelet]] — Primary node agent; most node issues trace here
- [[Static Pods]] — Control plane components on nodes
- [[kube-proxy]] — Node-level service networking
- [[OS Upgrade]] — Intentional node maintenance workflow

## Key Mental Model

A node is essentially **kubelet + container runtime + CNI + disk**. When a node goes `NotReady`, work through this chain: kubelet → container runtime → network → resources. The kubelet is the first place to look because if it's not running, nothing else on that node works from Kubernetes' perspective.
