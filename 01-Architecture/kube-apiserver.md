---
tags: [cka/architecture, architecture]
aliases: [API Server, apiserver]
---

# kube-apiserver

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[etcd]], [[kube-scheduler]], [[kube-controller-manager]], [[kubelet]], [[Cluster Architecture]]

## Overview

The **kube-apiserver** is the central management component of Kubernetes. It exposes the Kubernetes API, handles all REST requests, validates them, and persists cluster state to [[etcd]]. It is the **only component that reads from and writes to etcd** — all other components communicate exclusively through it.

> [!tip] Exam Tip
> Static Pod manifest location is heavily tested: `/etc/kubernetes/manifests/kube-apiserver.yaml`

## Role in the Control Plane

- Single entry point for all cluster operations
- Authenticates, authorizes, and validates every request
- Serves as the communication hub — [[kubelet]], [[kube-scheduler]], and [[kube-controller-manager]] all talk to it
- Watches [[etcd]] for changes and serves cached data for efficiency

## Key Features

### RESTful API

- Provides HTTP/HTTPS endpoints for CRUD operations (e.g., `/api/v1/pods`)
- Supports versioning (`core v1`, `apps/v1`) for backward compatibility
- See [[API Groups]] for full structure

### Authentication

- Mechanisms: client certificates, bearer tokens (JWT), webhooks
- Validates client identity before processing any request

### Authorization

- Modes: [[RBAC]] (default), ABAC, Node, Webhook
- Checks permissions using policies (Role/ClusterRole bindings)

### Admission Control

- Plugins: `MutatingAdmissionWebhook`, `ValidatingAdmissionWebhook`, `NamespaceLifecycle`, `ResourceQuota`
- Validates or mutates resources before persistence

## Deployment

Runs as a [[Static Pods|Static Pod]] on control-plane nodes:

```bash
/etc/kubernetes/manifests/kube-apiserver.yaml
```

Highly available via multiple instances behind a load balancer.

## Configuration

Key flags:

```bash
--etcd-servers=https://127.0.0.1:2379
--authorization-mode=Node,RBAC
--enable-admission-plugins=NodeRestriction
--secure-port=6443
--audit-policy-file=/etc/kubernetes/audit-policy.yaml
--audit-log-path=/var/log/audit.log
```

Key ports:
- `6443` — secure HTTPS (default)
- `8080` — insecure (deprecated, should be disabled)

## Key Commands

```bash
# Health check
curl https://localhost:6443/healthz --cacert /etc/kubernetes/pki/ca.crt

# Check component status
kubectl get componentstatuses

# View apiserver pod
kubectl get pod kube-apiserver-<node> -n kube-system

# View logs
kubectl logs kube-apiserver-<node> -n kube-system
# OR
journalctl -u kube-apiserver

# Inspect manifest
cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

## Common Issues / Troubleshooting

- **Certificate errors** → check `/etc/kubernetes/pki/`, verify expiration with `kubeadm certs check-expiration`
- **etcd connectivity** → check `--etcd-servers` flag, TLS certs for etcd
- **"connection refused"** → apiserver is down; check the static Pod manifest and kubelet logs
- **High load / timeouts** → tune `--max-requests-inflight`, check etcd disk latency
- **Unauthorized** → RBAC issue or wrong kubeconfig context

## Related Notes

- [[etcd]] — The only storage backend the apiserver writes to
- [[Cluster Architecture]] — Where apiserver fits in the big picture
- [[TLS in Kubernetes]] — Certificate chain for apiserver
- [[RBAC]] — Authorization model
- [[Static Pods]] — How apiserver is deployed
- [[Kubeconfig]] — How clients authenticate to apiserver

## Key Mental Model

The kube-apiserver is the **post office** of Kubernetes. Every component drops off and picks up mail here. Nothing is delivered directly. If the post office closes, the whole city freezes — existing mail keeps running, but nothing new gets processed.
