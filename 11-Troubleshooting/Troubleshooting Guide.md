---
tags: [cka/troubleshooting, troubleshooting]
aliases: [Troubleshooting, Debug, Diagnosis Workflow]
---

# Troubleshooting Guide

> **Exam Domain**: Troubleshooting (30%) — highest weight domain
> **Related**: [[Node Troubleshooting]], [[Pod Troubleshooting]], [[kubectl]], [[kubelet]], [[kube-apiserver]]

## Overview

Troubleshooting is **30% of the CKA exam** — the single most important domain. This guide provides a systematic workflow for diagnosing any cluster issue. The key is to always start at the **highest level** (is the cluster reachable?) and work **down** through layers until you find the failure.

> [!tip] Exam Tip
> Always run `kubectl describe` and `kubectl logs` first. Events section in `describe` output reveals 90% of issues.

## Master Diagnostic Workflow

```
1. Can I reach the cluster?          → kubectl cluster-info
2. Are control plane components OK?  → kubectl get pods -n kube-system
3. Are nodes healthy?                → kubectl get nodes
4. Is the resource in the right ns?  → kubectl get <resource> -A
5. What do events say?               → kubectl describe <resource>
6. What do logs say?                 → kubectl logs <pod>
7. Is networking OK?                 → kubectl exec ... -- curl/wget/ping
```

## Control Plane Health Check

```bash
# Overall cluster health
kubectl cluster-info
kubectl get componentstatuses

# Control plane pods (all should be Running)
kubectl get pods -n kube-system

# Describe a failing control plane pod
kubectl describe pod kube-apiserver-controlplane -n kube-system

# Check static pod manifests exist
ls /etc/kubernetes/manifests/

# API server logs (if apiserver is down, use journalctl)
kubectl logs kube-apiserver-<node> -n kube-system
journalctl -u kube-apiserver
```

## Node Health Check

See [[Node Troubleshooting]] for full details.

```bash
# Quick node status
kubectl get nodes

# Node conditions detail
kubectl describe node <node>    # Look for: Conditions section

# kubelet status
systemctl status kubelet
journalctl -u kubelet -n 50
```

## Pod Health Check

See [[Pod Troubleshooting]] for full details.

```bash
# Get pod status
kubectl get pods -n <namespace>
kubectl get pods -A    # All namespaces

# Describe for events (most useful command)
kubectl describe pod <pod> -n <namespace>

# Logs (current + previous)
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous

# Exec into running pod
kubectl exec -it <pod> -n <namespace> -- /bin/sh
```

## Service and Networking Troubleshooting

```bash
# Check service exists and has correct selector
kubectl get svc -n <namespace>
kubectl describe svc <service> -n <namespace>

# CRITICAL: Check endpoints (empty = selector mismatch)
kubectl get endpoints <service> -n <namespace>

# Test DNS resolution from within cluster
kubectl run dns-test --image=busybox --rm -it -- nslookup <service>
kubectl run dns-test --image=busybox --rm -it -- nslookup kubernetes

# Test service connectivity
kubectl run conn-test --image=busybox --rm -it -- wget -qO- http://<service>:<port>

# Check kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Check CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns
```

## Storage Troubleshooting

```bash
# Check PVC status (should be Bound)
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc-name> -n <namespace>

# Check PV status
kubectl get pv

# Check StorageClass
kubectl get storageclass

# PVC Pending → check for matching PV or StorageClass
kubectl describe pvc <pvc-name>    # Events show the reason
```

## etcd Troubleshooting

```bash
# Check etcd pod health
kubectl get pod etcd-controlplane -n kube-system
kubectl describe pod etcd-controlplane -n kube-system

# Test etcd connectivity
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

## Certificate Troubleshooting

```bash
# Check certificate expiration (single most useful cert command)
kubeadm certs check-expiration

# Inspect specific cert
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -E "Subject:|Not After"

# Renew all certs
kubeadm certs renew all
```

## RBAC Troubleshooting

```bash
# Test what a user/SA can do
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'    # Admin check

# Check roles and bindings
kubectl get roles,rolebindings -n dev
kubectl describe rolebinding <binding> -n dev
```

## Quick Reference: Common Error → Fix

| Error | Likely Cause | Fix |
|---|---|---|
| `Pending` pod | Scheduling failure | `kubectl describe pod` → check Events |
| `CrashLoopBackOff` | App crashing | `kubectl logs --previous` |
| `ImagePullBackOff` | Bad image or missing pull secret | Check image name, add imagePullSecrets |
| `OOMKilled` | Memory limit too low | Increase `limits.memory` |
| `CreateContainerConfigError` | Missing ConfigMap or Secret | Create the referenced resource |
| `NodeNotReady` | kubelet/network issue | `systemctl status kubelet` on node |
| Empty endpoints | Label selector mismatch | Check Service selector vs Pod labels |
| `403 Forbidden` | RBAC missing | `kubectl auth can-i` → add Role |
| `certificate expired` | TLS cert expired | `kubeadm certs renew all` |

## Related Notes

- [[Node Troubleshooting]] — Detailed node diagnosis
- [[Pod Troubleshooting]] — Detailed pod/container diagnosis
- [[kubectl]] — All diagnostic commands
- [[kubelet]] — Primary node component to check
- [[kube-apiserver]] — Control plane entry point

## Key Mental Model

Troubleshooting is **systematic elimination from top to bottom**: cluster → nodes → pods → containers → application. Every layer has its diagnostic command. Start broad (`kubectl get nodes`), zoom in (`kubectl describe pod`), go deeper (`kubectl logs`). The answer is almost always in the **Events section** or the **logs**.
