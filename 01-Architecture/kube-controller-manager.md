---
tags: [cka/architecture, architecture]
aliases: [Controller Manager, KCM]
---

# kube-controller-manager

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[etcd]], [[Deployments]], [[DaemonSets]], [[Pods]], [[Cluster Architecture]]

## Overview

The **kube-controller-manager** runs a collection of **controllers** that continuously watch the cluster and **reconcile actual state with desired state**. It is the engine of automation in Kubernetes — if the API server is the brain, the controller manager is the reflex system.

## Role in the Control Plane

- Connects to [[kube-apiserver]] and watches objects
- Takes corrective action whenever reality diverges from specification
- Runs as a [[Static Pods|Static Pod]] on control-plane nodes
- In HA clusters, uses **leader election** (only one active instance at a time)

## The Reconciliation Loop

Every controller follows the same pattern:

```
1. Watch resources via kube-apiserver
2. Detect state difference (desired vs actual)
3. Take corrective action via kube-apiserver
4. Repeat forever
```

## Core Controllers Included

| Controller | Responsibility |
|---|---|
| Node Controller | Detects node failures, evicts Pods |
| ReplicaSet Controller | Maintains Pod count for [[Deployments]] |
| Deployment Controller | Manages rolling updates and rollbacks |
| DaemonSet Controller | Ensures one Pod per Node for [[DaemonSets]] |
| Namespace Controller | Cleans up resources when namespace is deleted |
| Service Account Controller | Creates default service accounts |
| Job Controller | Manages batch jobs to completion |
| Endpoint Controller | Populates Endpoints for [[Services]] |

## Communication Flow

```
kube-controller-manager → kube-apiserver → etcd
```

- Never talks to [[kubelet]] directly
- Never writes to [[etcd]] directly
- All actions flow through the API server

## Deployment

Runs as a [[Static Pods|Static Pod]]:

```bash
/etc/kubernetes/manifests/kube-controller-manager.yaml
```

Key flags:
- `--controllers=*` — enable all controllers
- `--leader-elect=true`
- `--cluster-signing-cert-file`
- `--node-monitor-period=5s`

## Key Commands

```bash
# Check controller manager pod
kubectl get pod kube-controller-manager-<node> -n kube-system

# View logs
kubectl logs kube-controller-manager-<node> -n kube-system

# Inspect manifest
cat /etc/kubernetes/manifests/kube-controller-manager.yaml
```

## Common Issues / Troubleshooting

- **If KCM stops**: No new Pods created, scaling halts, failed Pods not replaced — cluster state slowly decays (existing Pods keep running)
- **Certificate errors** → check KCM TLS config in manifest
- **Leader election failures** → in HA setup, check lease objects in kube-system
- **Controller not reconciling** → check logs for specific controller errors

## Related Notes

- [[kube-apiserver]] — Only communication channel for KCM
- [[Deployments]] — Managed by Deployment Controller inside KCM
- [[DaemonSets]] — Managed by DaemonSet Controller inside KCM
- [[Static Pods]] — How KCM is deployed
- [[Cluster Architecture]] — KCM in context

## Key Mental Model

The kube-controller-manager is **Kubernetes' immune system**. It doesn't deploy workloads — it watches, notices drift, and relentlessly pushes the cluster back toward equilibrium. Declarative intent goes in. Relentless correction comes out.
