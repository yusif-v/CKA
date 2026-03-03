---
tags: [cka/architecture, architecture, cka/troubleshooting]
aliases: [Node Agent, kubelet agent]
---

# kubelet

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[Static Pods]], [[Pods]], [[kube-scheduler]], [[Cluster Architecture]]

## Overview

The **kubelet** is the primary node-level agent in Kubernetes. It runs on every worker node and ensures that [[Pods]] assigned to the node are running and healthy. The kubelet does **not** schedule Pods and does **not** talk directly to [[etcd]] — all communication flows through [[kube-apiserver]].

## Core Responsibilities

- Watches [[kube-apiserver]] for Pods bound to its Node
- Creates and manages containers via the container runtime (CRI)
- Mounts volumes and injects [[Secrets]] and [[ConfigMap]]s
- Executes liveness, readiness, and startup probes
- Reports Pod and Node status back to kube-apiserver
- Manages [[Static Pods]] by watching the manifest directory

## Pod Lifecycle Management

### Pod Creation Flow

```
1. kube-scheduler binds Pod to Node
2. kubelet retrieves PodSpec from kube-apiserver
3. Pull images via container runtime
4. Create containers with cgroups and namespaces
5. Start containers and probes
6. Report status back to apiserver
```

### Pod Termination Flow

```
1. Receive delete request with grace period
2. Send SIGTERM to containers
3. Wait for graceful shutdown
4. Send SIGKILL if grace period exceeded
```

## Health Probes

| Probe | Purpose |
|---|---|
| Liveness | Detects dead containers; triggers restart |
| Readiness | Controls Service endpoint inclusion |
| Startup | Disables liveness for slow-starting containers |

## Configuration

Runs as a **systemd service** (not a static Pod):

```bash
# Service status
systemctl status kubelet

# Config file
/var/lib/kubelet/config.yaml

# Key flags
--config=/var/lib/kubelet/config.yaml
--kubeconfig=/etc/kubernetes/kubelet.conf
--container-runtime-endpoint=unix:///var/run/containerd/containerd.sock
--pod-manifest-path=/etc/kubernetes/manifests
```

> [!tip] Exam Tip
> The kubelet runs as a systemd service, not a static Pod. To restart it: `systemctl restart kubelet`

## Node Status Reporting

- Registers the Node object on startup with [[Labels]] and taints
- Updates Node conditions: `Ready`, `MemoryPressure`, `DiskPressure`
- Maintains node leases for heartbeat (`kube-node-lease` namespace)

## Security Model

- Uses client certificates to authenticate to [[kube-apiserver]]
- Node Authorizer limits what each kubelet can access
- Supports automatic certificate rotation

## Key Commands

```bash
# Check kubelet status
systemctl status kubelet

# Restart kubelet
systemctl restart kubelet

# View kubelet logs
journalctl -u kubelet -f
journalctl -u kubelet --since "10 minutes ago"

# Check node conditions
kubectl describe node <node-name>
kubectl get node <node-name> -o yaml

# Check pods on specific node
kubectl get pods --field-selector spec.nodeName=<node-name>
```

## Common Issues / Troubleshooting

- **Node NotReady** → check `systemctl status kubelet` and `journalctl -u kubelet`
- **Pod stuck in ContainerCreating** → volume, image pull, or CNI issue; check kubelet logs
- **kubelet not starting** → check config file syntax and certificate validity
- **Wrong `--pod-manifest-path`** → Static Pods not being picked up
- **CRI socket not found** → container runtime not running or wrong endpoint

## Related Notes

- [[kube-apiserver]] — All kubelet communication goes through it
- [[Static Pods]] — Managed directly by kubelet from manifest dir
- [[Node Troubleshooting]] — Full node diagnosis workflow
- [[Pods]] — What kubelet ultimately manages
- [[TLS in Kubernetes]] — kubelet certificate rotation

## Key Mental Model

The kubelet is the **foreman on each job site**. It receives work orders (PodSpecs) from headquarters (apiserver), manages the crew (containers), and reports progress back. When the foreman goes silent, the site goes dark — the Node becomes NotReady.
