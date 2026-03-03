---
tags: [cka/architecture, architecture, cli]
aliases: [kubeconfig, kubectl config, cluster config]
---

# Kubeconfig

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kubectl]], [[RBAC]], [[TLS in Kubernetes]], [[kubeadm]]

## Overview

**Kubeconfig** is a configuration file that tells Kubernetes clients **how to connect to a cluster**. It defines where the cluster is, who you are (authentication), and what namespace/context to use. [[kubectl]] reads kubeconfig to talk to [[kube-apiserver]].

> [!warning] Exam Tip
> Wrong context = deploying to the wrong cluster. Always verify with `kubectl config current-context` before running destructive commands.

## Default Location

```bash
~/.kube/config

# Override with environment variable
export KUBECONFIG=/path/to/config

# Or use flag
kubectl --kubeconfig=/path/to/config get pods
```

## Kubeconfig Structure

A kubeconfig file has four sections:

```yaml
apiVersion: v1
kind: Config

clusters:
- name: dev-cluster
  cluster:
    server: https://10.0.0.1:6443
    certificate-authority: /path/to/ca.crt

users:
- name: dev-user
  user:
    client-certificate: /path/to/dev-user.crt
    client-key: /path/to/dev-user.key

contexts:
- name: dev-context
  context:
    cluster: dev-cluster
    user: dev-user
    namespace: default

current-context: dev-context
```

- **clusters** — API server endpoints and CA certificates
- **users** — authentication credentials (certs, tokens)
- **contexts** — combination of cluster + user + namespace
- **current-context** — which context is active

## Key Commands

```bash
# View current config
kubectl config view

# View raw config (with certs)
kubectl config view --raw

# Show current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context dev-context

# Set default namespace for current context
kubectl config set-context --current --namespace=dev

# Add a new context
kubectl config set-context my-ctx \
  --cluster=my-cluster \
  --user=my-user \
  --namespace=my-ns
```

## Authentication Methods in Kubeconfig

| Method | Config Field | Notes |
|---|---|---|
| Client certificates | `client-certificate` + `client-key` | Most common in kubeadm |
| Bearer tokens | `token` | Service accounts, OIDC |
| Exec plugin | `exec` | Cloud provider auth (gcloud, aws) |

## Multiple Kubeconfig Files

```bash
# Merge multiple configs
export KUBECONFIG=~/.kube/config:~/.kube/staging-config

# Flatten to single file
kubectl config view --merge --flatten > ~/.kube/merged-config
```

## kubeadm-Generated Configs

kubeadm creates these files in `/etc/kubernetes/`:

| File | Purpose |
|---|---|
| `admin.conf` | Full cluster admin access |
| `kubelet.conf` | kubelet → apiserver auth |
| `controller-manager.conf` | KCM → apiserver auth |
| `scheduler.conf` | Scheduler → apiserver auth |

## Common Issues / Troubleshooting

- **Wrong context** → `kubectl config current-context` to verify before doing anything
- **Expired certificates** → regenerate user cert or use `kubeadm certs renew`
- **Connection refused** → check server address in cluster config
- **Namespace not found** → namespace in context doesn't exist; create it or switch namespace
- **Multiple configs conflicting** → use explicit `--kubeconfig` flag

## Related Notes

- [[kubectl]] — Uses kubeconfig for every command
- [[RBAC]] — The user identity in kubeconfig is what RBAC evaluates
- [[TLS in Kubernetes]] — Client certs in kubeconfig are signed by cluster CA
- [[kubeadm]] — Generates kubeconfig files during cluster init

## Key Mental Model

Kubeconfig is your **passport** to Kubernetes. Cluster = country. User = identity. Context = travel plan. Switch the passport incorrectly and you might deploy to **production while thinking you're in dev**.
