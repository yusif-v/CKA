---
tags: [cka/architecture, security]
aliases: [TLS, Certificates, PKI, mTLS, x509]
---

# TLS in Kubernetes

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[kube-apiserver]], [[etcd]], [[kubelet]], [[kubeadm]], [[Kubeconfig]], [[RBAC]]

## Overview

**TLS (Transport Layer Security)** in Kubernetes secures **all communication** between cluster components using X.509 certificates. Every control-plane and node interaction is authenticated and encrypted. Kubernetes is a **certificate-driven system** — without valid TLS, components cannot communicate.

> [!tip] Exam Tip
> Certificate expiration is a common exam scenario. Know: `kubeadm certs check-expiration` and `kubeadm certs renew all`

## Why TLS Matters

- Prevents man-in-the-middle attacks between components
- Ensures component identity (authentication)
- Encrypts all control-plane traffic
- Enforces trust boundaries

## Certificate Authority (CA)

Kubernetes uses a **cluster CA** to sign all component certificates:

```bash
# CA files (root of trust)
/etc/kubernetes/pki/ca.crt   # Public certificate
/etc/kubernetes/pki/ca.key   # Private key — protect this
```

The CA is the **root of trust** for the entire cluster.

## Common Certificates

| Component | Certificate Location | Purpose |
|---|---|---|
| kube-apiserver | `/etc/kubernetes/pki/apiserver.crt` | Serves HTTPS |
| kube-apiserver (etcd client) | `/etc/kubernetes/pki/apiserver-etcd-client.crt` | Connects to etcd |
| kube-apiserver (kubelet client) | `/etc/kubernetes/pki/apiserver-kubelet-client.crt` | Connects to kubelet |
| etcd server | `/etc/kubernetes/pki/etcd/server.crt` | etcd serving cert |
| etcd peer | `/etc/kubernetes/pki/etcd/peer.crt` | etcd cluster communication |
| kubelet | `/var/lib/kubelet/pki/kubelet.crt` | Node identity |
| Admin (kubectl) | `~/.kube/config` | Admin client cert |

## TLS Communication Paths

```
kubectl → kube-apiserver          (client cert auth)
kube-apiserver ↔ etcd             (mutual TLS)
kube-apiserver → kubelet          (client cert auth)
kubelet → kube-apiserver          (node bootstrap cert)
kube-controller-manager → apiserver
kube-scheduler → apiserver
```

All paths use **mutual TLS** — both sides verify each other.

## Certificate Inspection

```bash
# Check all certificate expiration dates
kubeadm certs check-expiration

# Inspect a specific certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A2 "Validity"

# Check Subject (who the cert is for)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "Subject:"

# Check SANs (Subject Alternative Names)
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -A5 "Subject Alternative Name"
```

## Certificate Renewal

```bash
# Renew all control plane certs (run on control-plane node)
kubeadm certs renew all

# Renew specific cert
kubeadm certs renew apiserver

# Restart control plane components after renewal
# (static pods restart automatically when manifest changes)
# Force restart by moving + restoring manifests
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

## kubelet Certificate Rotation

kubelet supports automatic certificate rotation:

```yaml
# In kubelet config
rotateCertificates: true
```

Controlled by [[kube-controller-manager]] with `--cluster-signing-cert-file`.

## Key Commands

```bash
# Check certificate expiration
kubeadm certs check-expiration

# Renew all certs
kubeadm certs renew all

# Inspect certificate
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout

# View kubeconfig cert
kubectl config view --raw | grep client-certificate-data | \
  awk '{print $2}' | base64 -d | openssl x509 -text -noout

# Check TLS handshake to apiserver
curl -k https://localhost:6443/healthz
```

## Common Issues / Troubleshooting

- **"certificate has expired"** → run `kubeadm certs check-expiration`; renew with `kubeadm certs renew all`
- **Clock skew** → TLS fails if node time is off; sync with `timedatectl` and NTP
- **Wrong SAN** → cert doesn't cover the hostname/IP being used; regenerate cert
- **Misconfigured kubeconfig** → wrong CA cert or expired client cert; regenerate admin.conf
- **etcd TLS errors** → check `/etc/kubernetes/pki/etcd/` certs are valid

## Related Notes

- [[kubeadm]] — Manages certificate lifecycle
- [[kube-apiserver]] — Central TLS endpoint for the cluster
- [[etcd]] — Uses mutual TLS for all communications
- [[kubelet]] — Uses node certificates for API server authentication
- [[Kubeconfig]] — Embeds client certs for kubectl authentication

## Key Mental Model

TLS is the **nervous system insulation** of Kubernetes. Signals travel constantly between components. TLS ensures those signals are **private, authentic, and untampered**. Expired certificates are one of the most common and time-sensitive cluster failures — monitor and renew proactively.
