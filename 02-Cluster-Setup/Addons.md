---
tags: [cka/architecture, architecture]
aliases: [Addons, Cluster Addons, CNI, CoreDNS, metrics-server]
---

# Addons

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubeadm]], [[Cluster Architecture]], [[Network Namespaces]], [[Autoscaling]], [[Services]]

## Overview

**Addons** are cluster-level components that extend Kubernetes with essential functionality. They run as [[Pods]] inside the cluster (typically in `kube-system`) and provide networking, DNS, monitoring, and UI capabilities. Some addons are **required** for a functional cluster; others are optional.

> [!tip] Exam Tip
> **CoreDNS** and a **CNI plugin** are required for a working cluster. `kubeadm init` installs CoreDNS automatically — but CNI must be installed manually. Without CNI, all Pods stay `Pending`.

## Required vs Optional Addons

| Addon | Required | Purpose |
|---|---|---|
| CNI Plugin (Flannel, Calico, Cilium) | ✅ Yes | Pod networking and IP assignment |
| CoreDNS | ✅ Yes | Service discovery and DNS resolution |
| metrics-server | Optional | CPU/memory metrics for HPA and `kubectl top` |
| Kubernetes Dashboard | Optional | Web-based cluster UI |
| Ingress Controller | Optional | HTTP/HTTPS routing into the cluster |

---

## CNI Plugin (Container Network Interface)

The **CNI plugin** is responsible for Pod networking — assigning IPs, setting up routes, and enabling Pod-to-Pod communication across nodes. Without it, no Pod can communicate.

> [!warning]
> `kubeadm init` does **not** install a CNI plugin. You must install one manually before Pods can run.

### Popular CNI Plugins

| Plugin | Network Model | Supports NetworkPolicy |
|---|---|---|
| Flannel | Overlay (VXLAN) | ❌ No |
| Calico | BGP / Overlay | ✅ Yes |
| Cilium | eBPF-based | ✅ Yes |
| Weave | Overlay | ✅ Yes |

```bash
# Install Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Install Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verify CNI pods are running
kubectl get pods -n kube-system
```

> [!tip] Exam Tip
> If [[Network Policy]] is required, use **Calico** or **Cilium** — Flannel does not enforce NetworkPolicy rules.

---

## CoreDNS

**CoreDNS** is the cluster DNS server. It enables [[Services]] to be resolved by name inside the cluster. Every Pod is configured to use CoreDNS as its DNS resolver by default.

```
Pod → CoreDNS → Service name → ClusterIP
```

### DNS Resolution Pattern

```
<service-name>.<namespace>.svc.cluster.local
```

```bash
# CoreDNS runs as a Deployment in kube-system
kubectl get deployment coredns -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns

# ConfigMap controls CoreDNS behavior
kubectl get configmap coredns -n kube-system -o yaml

# Test DNS from inside a Pod
kubectl run test --image=busybox --rm -it -- nslookup kubernetes
kubectl run test --image=busybox --rm -it -- nslookup my-service.default.svc.cluster.local
```

### Common CoreDNS Issues

```bash
# Check CoreDNS logs
kubectl logs -n kube-system -l k8s-app=kube-dns

# Restart CoreDNS pods
kubectl rollout restart deployment coredns -n kube-system
```

---

## metrics-server

**metrics-server** collects CPU and memory usage from [[kubelet]] on each node and exposes them via the Kubernetes Metrics API. Required for:
- `kubectl top pods` / `kubectl top nodes`
- [[Autoscaling|Horizontal Pod Autoscaler (HPA)]]

```bash
# Install metrics-server
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verify it's running
kubectl get deployment metrics-server -n kube-system

# Use it
kubectl top nodes
kubectl top pods -A
```

> [!tip] Exam Tip
> If `kubectl top` returns `error: Metrics API not available`, metrics-server is not installed or not ready.

---

## Kubernetes Dashboard

A web-based UI for managing and observing cluster resources. Not installed by default.

```bash
# Install Dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Access via kubectl proxy
kubectl proxy
# Open: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

---

## Ingress Controller

An **Ingress Controller** is required to make [[Ingress]] resources functional. Without one, Ingress objects exist but do nothing.

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

# Verify
kubectl get pods -n ingress-nginx
```

See [[Ingress]] for full details on routing rules.

---

## Key Commands

```bash
# Check all addon pods in kube-system
kubectl get pods -n kube-system

# Check CoreDNS
kubectl get deployment coredns -n kube-system

# Check metrics-server
kubectl top nodes
kubectl top pods -A

# Check CNI is working (pods should have IPs)
kubectl get pods -A -o wide

# Verify DNS resolution
kubectl run test --image=busybox --rm -it -- nslookup kubernetes
```

---

## Common Issues / Troubleshooting

| Issue | Cause | Fix |
|---|---|---|
| All Pods stuck `Pending` | CNI not installed | Install a CNI plugin |
| Pods have no IP | CNI misconfigured | Check CNI pod logs in `kube-system` |
| Service DNS not resolving | CoreDNS not running | `kubectl get pods -n kube-system`, check CoreDNS logs |
| `kubectl top` fails | metrics-server not installed | Install metrics-server |
| HPA shows `<unknown>` metrics | metrics-server missing | Install metrics-server |
| NetworkPolicy not enforced | CNI doesn't support it | Switch to Calico or Cilium |
| Ingress rules not routing | No Ingress Controller | Install NGINX or another Ingress Controller |

---

## Related Notes

- [[kubeadm]] — Installs CoreDNS automatically; CNI must be added manually
- [[Network Namespaces]] — CNI plugins wire up Pod network namespaces
- [[Network Policy]] — Requires a CNI that supports policy enforcement (Calico, Cilium)
- [[Ingress]] — Requires an Ingress Controller addon to function
- [[Autoscaling]] — HPA depends on metrics-server being installed
- [[Cluster Architecture]] — Addons are part of the cluster's operational layer

---

## Key Mental Model

Kubernetes core gives you the **skeleton** — API server, scheduler, controller manager. Addons are the **organs**: CNI is the circulatory system (networking), CoreDNS is the nervous system (name resolution), metrics-server is the sensory system (observability). Without the right organs, the skeleton can't do much.
