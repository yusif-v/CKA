---
tags: [cka/troubleshooting, cka/architecture, cli, troubleshooting]
aliases: [crictl, CRI CLI, container runtime CLI]
---

# crictl

> **Exam Domain**: Troubleshooting (30%)
> **Related**: [[kubelet]], [[Static Pods]], [[Pods]], [[Control Plane Failure Troubleshooting]], [[Node Troubleshooting]], [[Cluster Architecture]]

## Overview

**crictl** is a command-line tool for interacting directly with a **CRI-compatible container runtime** (such as containerd or CRI-O), bypassing Kubernetes entirely. It is used for low-level container and image inspection on a node — especially when `kubectl` is unavailable because the [[kube-apiserver]] is down. Every node in a Kubernetes cluster has a container runtime; `crictl` gives you direct access to it.

> [!tip] Exam Tip
> Use `crictl` when the API server is down and `kubectl` won't work. It is your primary tool for diagnosing control plane component containers and static pod failures directly on the node.

---

## crictl vs kubectl vs docker

| Feature | `crictl` | `kubectl` | `docker` |
|---|---|---|---|
| Talks to | Container runtime (CRI) | kube-apiserver | Docker daemon |
| Works without API server | ✅ Yes | ❌ No | ❌ (not used in k8s) |
| Sees Kubernetes metadata | ❌ Limited | ✅ Full | ❌ No |
| Used for | Node-level debug | Cluster management | Legacy only |
| Scope | Single node | Entire cluster | Single node |

---

## Runtime Endpoint

`crictl` needs to know where the container runtime socket is. In most kubeadm clusters, the runtime is **containerd**:

```bash
# Default containerd socket (usually auto-detected)
unix:///var/run/containerd/containerd.sock

# Set explicitly if needed
crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps

# Or export as env var
export CONTAINER_RUNTIME_ENDPOINT=unix:///var/run/containerd/containerd.sock

# Or configure permanently
cat /etc/crictl.yaml
# runtime-endpoint: unix:///var/run/containerd/containerd.sock
# image-endpoint: unix:///var/run/containerd/containerd.sock
```

---

## Key Commands

### Container Operations

```bash
# List running containers
crictl ps

# List ALL containers (including stopped/failed)
crictl ps -a

# Inspect a container (full JSON detail)
crictl inspect <container-id>

# Get container logs
crictl logs <container-id>

# Stream container logs live
crictl logs -f <container-id>

# Execute a command inside a running container
crictl exec -it <container-id> /bin/sh

# Stop a container
crictl stop <container-id>

# Remove a container
crictl rm <container-id>
```

### Pod Operations

> [!note] CRI "Pods" vs Kubernetes Pods
> In CRI terms, a "pod sandbox" is the network namespace + pause container that wraps containers. These map to Kubernetes Pods but `crictl` sees them at the lower CRI layer.

```bash
# List pod sandboxes (CRI-level pods)
crictl pods

# List pods with full detail
crictl pods --verbose

# Filter pods by name
crictl pods --name <name>

# Filter pods by namespace
crictl pods --namespace kube-system

# Inspect a pod sandbox
crictl inspectp <pod-id>

# Remove a pod sandbox (stops all containers in it first)
crictl stopp <pod-id>
crictl rmp <pod-id>
```

### Image Operations

```bash
# List cached images on the node
crictl images

# Pull an image
crictl pull nginx:latest

# Inspect an image
crictl inspecti <image-id>

# Remove an image
crictl rmi <image-id>

# Remove ALL unused images (disk cleanup)
crictl rmi --prune
```

### Runtime Info

```bash
# Check runtime info and version
crictl info
crictl version

# Check runtime status
crictl stats          # Container CPU/memory stats
crictl stats -a       # All containers
```

---

## Common Exam Workflows

### Find and read logs for a failing static pod

```bash
# SSH to control-plane node first
ssh controlplane

# List all containers, including failed ones
crictl ps -a

# Find the kube-apiserver container (may be in Exited state)
crictl ps -a | grep kube-apiserver

# Read its logs
crictl logs <container-id>

# Or get the last N lines
crictl logs --tail=50 <container-id>
```

### Identify why a container keeps restarting

```bash
# Show all containers with restart counts
crictl ps -a

# Inspect the container for exit code and error
crictl inspect <container-id>
# Look for: exitCode, reason, message

# Check logs from the last run
crictl logs <container-id>
```

### Check what images are on a node

```bash
# Useful when debugging ImagePullBackOff
crictl images

# Prune unused images to free disk space
crictl rmi --prune
```

### Verify the container runtime is healthy

```bash
# Runtime must be healthy for kubelet to function
crictl info

# Check containerd service directly
systemctl status containerd

# Restart containerd if needed
systemctl restart containerd
```

---

## Reading `crictl ps -a` Output

```
CONTAINER   IMAGE         CREATED         STATE      NAME                   ATTEMPT   POD ID
a1b2c3d4    sha256:...    2 minutes ago   Running    kube-apiserver         0         x1y2z3
e5f6g7h8    sha256:...    5 minutes ago   Exited     kube-scheduler         3         p9q8r7
```

| Column | Meaning |
|---|---|
| `CONTAINER` | Container ID (truncated) |
| `STATE` | `Running`, `Exited`, `Created` |
| `NAME` | Container name from the pod spec |
| `ATTEMPT` | Restart count — high numbers indicate a crash loop |
| `POD ID` | CRI-level pod sandbox ID |

High `ATTEMPT` count = container crash-looping. Run `crictl logs <id>` to find out why.

---

## Common Issues / Troubleshooting

- **`crictl ps` returns nothing** → container runtime (containerd) is down; `systemctl status containerd`
- **Wrong runtime endpoint** → set `--runtime-endpoint` explicitly or configure `/etc/crictl.yaml`
- **Can't exec into a container** → container must be in `Running` state; use `crictl ps` to confirm
- **`crictl logs` shows no output** → container may not have written to stdout/stderr; check the app
- **Permission denied** → run as root (`sudo crictl ...`)

---

## Related Notes

- [[kubelet]] — Uses the CRI to start/stop containers; crictl talks to the same runtime
- [[Static Pods]] — Control plane component containers are visible via `crictl ps`
- [[Control Plane Failure Troubleshooting]] — Primary use case for crictl when kubectl is down
- [[Node Troubleshooting]] — crictl used to check container runtime health on nodes
- [[Image Security]] — `crictl images` shows what is cached on a node

---

## Key Mental Model

`crictl` is a **flashlight for the container runtime layer**. When the Kubernetes control plane is dark — no API server, no `kubectl` — `crictl` lets you see exactly what containers are running, what failed, and why, by going directly to the source. It doesn't know about Deployments or Services; it only knows about containers and sandboxes on **this node, right now**.
