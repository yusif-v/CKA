# Kubeconfig
## Overview

**Kubeconfig** is a configuration file that tells Kubernetes clients **how to connect to a cluster**.

It defines:

- **Where** the cluster is
- **Who** you are (authentication)
- **What** you are allowed to do (authorization context)

kubectl reads kubeconfig to talk to the API server.

## Default Location

```bash
~/.kube/config
```

You can override this with:

```bash
export KUBECONFIG=/path/to/config
```

## Kubeconfig Structure

A kubeconfig file contains **four main sections**:
- **clusters** – API server endpoints + CA cert
- **users** – authentication credentials
- **contexts** – cluster + user + namespace
- **current-context** – active context

## Example Kubeconfig

```yaml
apiVersion: v1
kind: Config
clusters:
- name: dev-cluster
  cluster:
    server: https://10.0.0.1:6443
    certificate-authority: ca.crt

users:
- name: dev-user
  user:
    client-certificate: dev-user.crt
    client-key: dev-user.key

contexts:
- name: dev-context
  context:
    cluster: dev-cluster
    user: dev-user
    namespace: default

current-context: dev-context
```

## Viewing Kubeconfig

```bash
kubectl config view
```

Show raw config:

```bash
kubectl config view --raw
```

## Switching Contexts

List contexts:

```bash
kubectl config get-contexts
```

Switch context:

```bash
kubectl config use-context dev-context
```

## Setting Namespace per Context

```bash
kubectl config set-context --current --namespace=prod
```

## Authentication Methods

Kubeconfig supports:
- Client certificates
- Bearer tokens
- Exec plugins (OIDC, cloud auth)
- Static tokens (deprecated)

🔗 Related:
- [[Authentication]]
- [[TLS in Kubernetes]]

## Multiple Kubeconfig Files

Merge configs:

```bash
export KUBECONFIG=config1:config2
kubectl config view --merge --flatten
```

## kubeadm and Kubeconfig

kubeadm creates:
- admin.conf
- kubelet.conf
- controller-manager.conf
- scheduler.conf

Location:

```bash
/etc/kubernetes/
```

🔗 Related:
- [[kubeadm]]

## Common Issues

- Wrong context selected
- Expired certificates
- Incorrect API server endpoint
- Missing CA certificates

## Best Practices

- Use separate contexts per environment
- Never share admin kubeconfig
- Protect private keys
- Use RBAC with least privilege
- Rotate credentials regularly

## Key Mental Model

Kubeconfig is your **passport** to Kubernetes.
- Cluster = country
- User = identity
- Context = travel plan

Switch the passport incorrectly, and you might deploy to **production while thinking you’re in dev**.