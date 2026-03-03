---
tags: [cka/architecture, architecture]
aliases: [Static Pod, Mirror Pod]
---

# Static Pods

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubelet]], [[kube-apiserver]], [[kube-scheduler]], [[etcd]], [[kubeadm]]

## Overview

**Static Pods** are [[Pods]] managed **directly by the [[kubelet]]**, not by the Kubernetes API server. They are defined as YAML files on a Node's filesystem, and the kubelet ensures they are always running. Static Pods are primarily used for **control-plane components**.

> [!tip] Exam Tip
> Static Pod manifest directory path is heavily tested: `/etc/kubernetes/manifests/`
> To create/modify a static Pod, edit the file on the node — not via kubectl.

## Key Characteristics

- Created and managed by [[kubelet]] directly
- **No controller** ([[ReplicaSets]], [[Deployments]], etc.)
- **Not scheduled** by [[kube-scheduler]]
- Automatically restarted if they fail
- Run even if [[kube-apiserver]] is down

## Control Plane as Static Pods

In kubeadm clusters, all control-plane components run as Static Pods:

```bash
ls /etc/kubernetes/manifests/
# etcd.yaml
# kube-apiserver.yaml
# kube-controller-manager.yaml
# kube-scheduler.yaml
```

This guarantees cluster recovery after reboots without external orchestration.

## Mirror Pods

Although Static Pods are not created via the API, [[kubelet]] creates a **mirror Pod** in [[kube-apiserver]] for visibility:

- Mirror Pods are **read-only**
- You cannot edit or delete them with `kubectl`
- They appear in `kubectl get pods -n kube-system`
- Name format: `<pod-name>-<node-name>`

## Configuration

Find the manifest path from kubelet config:

```bash
# Check kubelet flags
ps aux | grep kubelet | grep manifest

# Or check kubelet config file
cat /var/lib/kubelet/config.yaml | grep staticPodPath
```

Default path: `/etc/kubernetes/manifests`

## Example Static Pod Definition

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
  namespace: kube-system
spec:
  containers:
  - name: nginx
    image: nginx:1.25
```

Place this at `/etc/kubernetes/manifests/static-nginx.yaml` — kubelet will start it automatically.

## Static Pod vs Deployment

| Feature | Static Pod | Deployment |
|---|---|---|
| Managed by | kubelet | [[kube-controller-manager]] |
| Scheduled by | ❌ | [[kube-scheduler]] |
| Scalable | ❌ | ✅ |
| API-based creation | ❌ | ✅ |
| Rolling updates | ❌ | ✅ |

## Key Commands

```bash
# List static Pods (via mirror objects)
kubectl get pods -n kube-system

# Find manifest directory
ps aux | grep kubelet

# Create a static Pod (place file, kubelet picks it up)
cp my-pod.yaml /etc/kubernetes/manifests/

# Delete a static Pod (remove the file)
rm /etc/kubernetes/manifests/my-pod.yaml

# Check kubelet logs if Pod doesn't start
journalctl -u kubelet -f
```

## Common Issues / Troubleshooting

- **Static Pod not starting** → check file syntax; `kubelet` logs with `journalctl -u kubelet`
- **Mirror Pod stuck in terminating** → remove the manifest file; mirror Pod will disappear
- **Can't edit via kubectl** → must edit the YAML file directly on the node
- **Wrong manifest path** → kubelet ignoring the directory; check `--pod-manifest-path` flag

## Related Notes

- [[kubelet]] — Manages static Pods directly
- [[kube-apiserver]] — Shows read-only mirror Pods
- [[etcd]] — Control plane static Pods protect etcd state
- [[kubeadm]] — Creates static Pod manifests during `kubeadm init`
- [[Cluster Architecture]] — Static Pods are how the control plane bootstraps

## Key Mental Model

Static Pods are **Node-level guardians**. If Kubernetes were a city, controllers are city planners and Static Pods are emergency generators bolted to buildings. They exist so the cluster can **bootstrap and heal itself**, even when the control plane is wounded.
