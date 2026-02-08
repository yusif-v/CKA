# TLS in Kubernetes
## Overview

**TLS (Transport Layer Security)** in Kubernetes secures **all communication** between cluster components.

Every control-plane and node interaction is authenticated and encrypted using **X.509 certificates**.

Kubernetes is a **certificate-driven system**.

## Why TLS Matters

- Prevents man-in-the-middle attacks
- Ensures component identity
- Encrypts control-plane traffic
- Enforces trust boundaries

Without TLS, Kubernetes **does not function securely**.

## Components Using TLS
### Control Plane

- kube-apiserver
- kube-controller-manager
- kube-scheduler
- etcd

### Nodes

- kubelet
- kube-proxy

### Clients

- kubectl
- controllers
- webhooks

## Certificate Authority (CA)

Kubernetes uses a **cluster CA** to sign all certificates.

Default location:

```bash
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
```

The CA is the **root of trust**.

## Common Certificates

|**Component**|**Certificate**|
|---|---|
|API Server|apiserver.crt|
|kubelet|kubelet-client.crt|
|etcd|etcd-server.crt|
|Admin|admin.conf|

## TLS Communication Paths

```bash
kubectl → kube-apiserver
kube-apiserver ↔ etcd
kube-apiserver → kubelet
kubelet → kube-apiserver
```

All are **mutually authenticated**.

## kubeconfig Files

kubeconfig files store:
- Client certificate
- CA certificate
- API server endpoint

Location example:

```bash
~/.kube/config
```

🔗 Related:

- [[kubectl]]
- [[Authentication]]

## Inspect Certificates

Check certificate expiration:

```bash
kubeadm certs check-expiration
```

View certificate details:

```bash
openssl x509 -in apiserver.crt -text -noout
```

## Certificate Rotation

- kubelet rotates certificates automatically
- kubeadm can renew control-plane certs

Renew certs:

```bash
kubeadm certs renew all
```

Restart control-plane components after renewal.

## TLS for etcd

etcd uses **mutual TLS**:
- Client cert
- Server cert
- Peer cert

Certificates stored in:

```bash
/etc/kubernetes/pki/etcd/
```

🔗 Related:
- [[etcd]]
- [[etcdctl]]

## Webhooks & TLS

Admission webhooks use TLS to:
- Authenticate webhook servers
- Encrypt admission requests

🔗 Related:
- [[Admission Controller]]

## Best Practices

- Protect CA private key
- Monitor certificate expiration
- Enable automatic rotation
- Use short-lived certs where possible
- Avoid disabling TLS verification

## Common Pitfalls

- Expired certificates
- Clock skew causing TLS failures
- Incorrect SANs in certificates
- Misconfigured kubeconfig files

## Key Mental Model

TLS is the **nervous system insulation** of Kubernetes.

Signals travel constantly between components.
TLS ensures those signals are:
- Private
- Authentic
- Untampered

Without TLS, the system may still move —
but it cannot be trusted.