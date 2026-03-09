---
tags: [cka/networking, cka/architecture, networking, architecture]
aliases: [CNI, Container Network Interface, Flannel, Calico, Cilium, Pod Networking, CNI plugin]
---

# CNI Plugins

> **Exam Domain**: Services & Networking (20%) · Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[Cluster Architecture]], [[Pods]], [[Network Namespaces]], [[Network Policy]], [[kubeadm]], [[kube-proxy]], [[Addons]]

## Overview

**CNI (Container Network Interface)** is the standard API Kubernetes uses to delegate Pod networking to a pluggable plugin. The CNI plugin is responsible for assigning each Pod a unique IP, setting up the network interface inside the Pod's [[Network Namespaces|network namespace]], and enabling Pod-to-Pod communication across nodes. Without a CNI plugin, all Pods remain `Pending` and cannot communicate.

> [!warning]
> `kubeadm init` does **not** install a CNI plugin. You must install one manually immediately after cluster bootstrap — before any workload Pods can run.

---

## The Kubernetes Networking Model

Kubernetes mandates a flat networking model with three rules:

1. Every Pod gets a **unique cluster-wide IP**
2. Pods can reach **any other Pod** directly without NAT
3. Nodes can reach **any Pod** without NAT

CNI plugins are responsible for implementing this model. How they do it (overlay, BGP, eBPF) is an implementation detail — the contract to Kubernetes is the same.

---

## How CNI Works — Pod Creation Flow

```
kubectl apply → kube-apiserver → kube-scheduler assigns Node
                                        ↓
                                   kubelet on Node
                                        ↓
                          Container runtime creates Pod sandbox
                          (new network namespace created)
                                        ↓
                          kubelet calls CNI plugin binary
                          (/opt/cni/bin/<plugin>)
                                        ↓
                     CNI plugin:
                       1. Creates veth pair
                       2. Puts one end inside Pod namespace
                       3. Puts other end on host bridge/overlay
                       4. Assigns IP from Pod CIDR
                       5. Sets up routes
                                        ↓
                          Pod has unique IP — Ready
```

### CNI Configuration Location

```bash
# CNI plugin binaries
ls /opt/cni/bin/

# CNI network configuration
ls /etc/cni/net.d/

# Active config file (first alphabetically wins)
cat /etc/cni/net.d/10-flannel.conflist
cat /etc/cni/net.d/10-calico.conflist
```

---

## Plugin Comparison

| Plugin | Network Model | NetworkPolicy | Performance | Complexity |
|---|---|---|---|---|
| **Flannel** | Overlay (VXLAN) | ❌ No | Good | Low |
| **Calico** | BGP (or overlay) | ✅ Yes | Excellent | Medium |
| **Cilium** | eBPF | ✅ Yes | Excellent | High |
| **Weave** | Overlay (mesh) | ✅ Yes | Good | Low |

> [!tip] Exam Tip
> If the question involves [[Network Policy]], you **must** use Calico, Cilium, or Weave — Flannel does not enforce NetworkPolicy rules. If the exam asks you to install a CNI with NetworkPolicy support, choose **Calico**.

---

## Flannel

**Flannel** is the simplest CNI plugin. It creates an overlay network using VXLAN, encapsulating Pod traffic in UDP packets sent between nodes. Easy to install, no NetworkPolicy support.

```bash
# Install Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Flannel requires --pod-network-cidr=10.244.0.0/16 at kubeadm init
kubeadm init --pod-network-cidr=10.244.0.0/16
```

Flannel runs as a [[DaemonSets|DaemonSet]] — one Pod per node in `kube-flannel` or `kube-system` namespace.

```bash
# Verify Flannel is running
kubectl get pods -n kube-flannel
# or
kubectl get pods -n kube-system | grep flannel
```

### Flannel Architecture

```
Node A (10.244.1.0/24)          Node B (10.244.2.0/24)
┌─────────────────────┐         ┌─────────────────────┐
│  Pod (10.244.1.5)   │         │  Pod (10.244.2.7)   │
│       ↕ veth        │         │       ↕ veth        │
│    cni0 bridge      │         │    cni0 bridge      │
│       ↕             │         │       ↕             │
│    flannel.1        │◄─VXLAN─►│    flannel.1        │
│   (VTEP device)     │         │   (VTEP device)     │
└─────────────────────┘         └─────────────────────┘
```

---

## Calico

**Calico** is the most commonly used CNI in production and on the CKA exam. It supports both BGP (no encapsulation, native routing) and VXLAN overlay modes, and fully enforces [[Network Policy]].

```bash
# Install Calico (operator method — recommended)
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml

# Install Calico (manifest method — simpler for exam)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verify Calico pods are running
kubectl get pods -n kube-system | grep calico
# or if using operator:
kubectl get pods -n calico-system
```

Calico also installs `calicoctl` — a CLI for managing Calico-specific resources (BGP peers, IP pools, etc.).

```bash
# Check Calico node status
kubectl exec -n kube-system calico-node-<id> -- calico-node -bird-ready
```

---

## Cilium

**Cilium** uses **eBPF** (extended Berkeley Packet Filter) to implement networking at the Linux kernel level — bypassing iptables entirely. This makes it extremely performant and gives it deep observability capabilities. More complex to operate than Flannel or Calico.

```bash
# Install Cilium CLI
curl -L --remote-name-all https://github.com/cilium/cilium-cli/releases/latest/download/cilium-linux-amd64.tar.gz
tar xzvf cilium-linux-amd64.tar.gz
mv cilium /usr/local/bin/

# Install Cilium into cluster
cilium install

# Verify
cilium status
kubectl get pods -n kube-system | grep cilium
```

---

## Choosing a CNI — Decision Guide

```
Do you need NetworkPolicy enforcement?
  ├── No  → Flannel (simplest)
  └── Yes → Do you need eBPF / high performance?
              ├── No  → Calico (most common, exam default)
              └── Yes → Cilium
```

---

## Pod CIDR — kubeadm Init Requirement

Most CNI plugins require a `--pod-network-cidr` flag at `kubeadm init` to reserve an IP range for Pods:

| Plugin | Recommended CIDR |
|---|---|
| Flannel | `10.244.0.0/16` |
| Calico | `192.168.0.0/16` (default) or any |
| Cilium | `10.0.0.0/8` (default) or any |

```bash
# Example: initialise with Flannel CIDR
kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<node-ip>
```

> [!warning]
> If you initialise without the correct CIDR for your chosen CNI, the CNI may fail to assign Pod IPs. The CIDR cannot be changed after cluster init without rebuilding.

---

## Key Commands

```bash
# Check if CNI is installed and running
kubectl get pods -n kube-system
kubectl get pods -A | grep -E "flannel|calico|cilium|weave"

# Check Pod IPs are being assigned (CNI working = Pods have IPs)
kubectl get pods -A -o wide

# Inspect CNI config on a node (SSH to node)
ls /etc/cni/net.d/
cat /etc/cni/net.d/*.conf*

# List available CNI binaries on a node
ls /opt/cni/bin/

# Check kubelet CNI configuration
cat /var/lib/kubelet/config.yaml | grep -i cni

# Test Pod-to-Pod connectivity across nodes
kubectl run test-a --image=busybox --rm -it -- ping <pod-ip-on-other-node>

# Identify which CNI is installed
kubectl get pods -n kube-system -o wide | grep -E "calico|flannel|cilium|weave"
kubectl get daemonset -n kube-system
```

---

## Common Issues / Troubleshooting

- **All Pods stuck `Pending`** → CNI not installed; `kubectl get pods -n kube-system` will show no CNI pods; install a CNI plugin
- **Pods have no IP (`<none>`)** → CNI installed but misconfigured; check CNI pod logs: `kubectl logs -n kube-system <cni-pod>`
- **Pod-to-Pod communication failing across nodes** → CNI overlay not routing correctly; check CNI DaemonSet pods are Running on all nodes
- **NetworkPolicy not enforced** → using Flannel, which doesn't support NetworkPolicy; switch to Calico or Cilium
- **CNI pods CrashLoopBackOff** → CIDR mismatch between `kubeadm init --pod-network-cidr` and CNI config; or missing kernel modules
- **Node stays `NotReady` after joining** → CNI not yet running on that node; wait for DaemonSet to schedule CNI Pod, or check for taints blocking it
- **`/etc/cni/net.d/` is empty** → CNI never installed; apply the CNI manifest
- **Multiple `.conf` files in `/etc/cni/net.d/`** → kubelet uses the first alphabetically; stale configs from a previous CNI can conflict; remove old files

---

## Related Notes

- [[Network Namespaces]] — CNI wires up Linux network namespaces to give each Pod its IP
- [[Network Policy]] — Requires a CNI that supports enforcement (Calico, Cilium, Weave)
- [[kubeadm]] — Bootstrap tool; does not install CNI; `--pod-network-cidr` must match CNI
- [[kube-proxy]] — Handles Service routing (iptables/IPVS); CNI handles Pod-to-Pod routing — distinct responsibilities
- [[Addons]] — CNI is a required cluster addon
- [[Pods]] — Every Pod gets its IP from the CNI plugin
- [[CoreDNS]] — Depends on CNI being functional; DNS resolution fails if Pods have no network

---

## Key Mental Model

Kubernetes builds the roads (the networking model and contracts) but doesn't lay the tarmac. The **CNI plugin is the road crew** — it physically builds the connections between Pods using whatever technique it prefers (tunnels, BGP, eBPF). Kubernetes doesn't care how the road is built, only that Pods can drive on it. Pick the road crew based on what features you need: Flannel for simplicity, Calico for policy, Cilium for performance.
