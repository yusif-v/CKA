# Static Pods
## Overview

**Static Pods** are Pods **managed directly by the kubelet**, not by the Kubernetes API server.

They are defined as **YAML files on a Node’s filesystem**, and the kubelet ensures they are always running.

Static Pods are mainly used for **control-plane components**.

## Key Characteristics

- Created and managed by [[kubelet]]
- **No controller** ([[ReplicaSet]], [[Deployment]], etc.)
- **Not scheduled** by [[kube-scheduler]]
- Defined locally on the Node
- Automatically restarted if they fail

## How Static Pods Work

1. kubelet watches a directory (e.g. /etc/kubernetes/manifests)
2. A Pod manifest appears in the directory
3. kubelet creates the Pod directly
4. kubelet keeps the Pod running

Even if the API server is down, Static Pods continue running.

## Control Plane Usage

Most Kubernetes installations run control-plane components as Static Pods:
- [[kube-apiserver]]
- [[kube-controller-manager]]
- [[kube-scheduler]]
- [[etcd]]

This guarantees cluster recovery after reboots.

## Static Pod Mirror Objects

Although Static Pods are not created via the API:
- kubelet creates a **mirror Pod** in the API server
- Mirror Pods are **read-only**
- You cannot edit or delete them with kubectl

Mirror Pods exist only for visibility.

## Static Pod Configuration

Common kubelet flags:

```bash
--pod-manifest-path=/etc/kubernetes/manifests
```

or via kubelet config file.

## Static Pod Definition Example

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: static-nginx
spec:
  containers:
  - name: nginx
    image: nginx
```

Place this file on the Node:

```bash
/etc/kubernetes/manifests/static-nginx.yaml
```

## Limitations

Static Pods:
- Cannot be scaled
- Cannot be updated via kubectl
- Do not support rolling updates
- Do not use controllers

To update a Static Pod, you must **edit the file on the Node**.

## Static Pods vs Controllers

|**Feature**|**Static Pod**|**Deployment**|
|---|---|---|
|Managed by|kubelet|Controller|
|Scheduled by|❌|[[kube-scheduler]]|
|Scalable|❌|✅|
|API-based|❌|✅|

## Debugging Static Pods

List Static Pods:

```bash
kubectl get pods -n kube-system
```

Find manifest source:

```bash
ps aux | grep kubelet
```

Check kubelet logs:

```bash
journalctl -u kubelet
```

## Key Mental Model

Static Pods are **Node-level guardians**.

If Kubernetes were a city:
- Controllers are city planners
- Static Pods are emergency generators bolted to the buildings

They exist so the cluster can **bootstrap and heal itself**, even when the control plane is wounded.