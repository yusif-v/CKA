# kube-controller-manager
## Overview

The **kube-controller-manager** runs a collection of **controllers** that continuously watch the cluster and **reconcile actual state with desired state**.

It is the **engine of automation** in Kubernetes.

If the API server is the brain, the controller manager is the reflex system.

## Role in the Control Plane

- Connects to [[kube-apiserver]]
- Watches objects stored in etcd
- Takes action when reality diverges from the specification
- Runs as a **Static Pod** on control-plane nodes

Without it, nothing heals, scales, or self-corrects.

## Controller Model

Each controller follows the same loop:
1. Watch resources via the API
2. Detect state differences
3. Take corrective action
4. Repeat forever

This is the **reconciliation loop**.

## Core Controllers (High-Level)

The kube-controller-manager includes many controllers, such as:

- [[Node Controller]]
- [[ReplicaSet Controller]]
- [[Deployment Controller]]
- [[DaemonSet Controller]]
- [[Namespace Controller]]
- [[Service Account Controller]]
- [[Job Controller]]
- [[Endpoint Controller]]

Each controller is logically independent.

## Leader Election

In HA clusters:
- Multiple controller-manager instances run
- Only one is **active leader**
- Others stay in standby

Leader election uses **leases stored in etcd**.

## Communication Flow

- Watches objects through [[kube-apiserver]]
- Never talks to [[kubelet]] directly
- All actions go through the API server

This preserves strict control-plane boundaries.

## Failure Behavior

If kube-controller-manager stops:
- No new Pods are created
- Failed Pods are not replaced
- Scaling stops
- Cluster state slowly decays

Existing Pods continue running.

## Configuration

Configured using command-line flags or config file.
Common flags:
- --controllers=*
- --leader-elect=true
- --cluster-signing-cert-file
- --node-monitor-period

Runs as a Static Pod defined in:

```bash
/etc/kubernetes/manifests/kube-controller-manager.yaml
```

## Observability

Check status:

```bash
kubectl get pods -n kube-system
```

View logs:

```bash
kubectl logs kube-controller-manager-<node> -n kube-system
```

## Key Mental Model

The kube-controller-manager is **Kubernetes’ immune system**.
It doesn’t deploy workloads itself.
It watches, notices drift, and relentlessly pushes the cluster back toward equilibrium.
Declarative intent goes in.
Relentless correction comes out.