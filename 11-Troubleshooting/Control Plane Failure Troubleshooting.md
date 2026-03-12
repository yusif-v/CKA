---
tags: [cka/troubleshooting, cka/architecture, troubleshooting, architecture]
aliases: [Control Plane Failure, Control Plane Debug, Control Plane Troubleshooting]
---

# Control Plane Failure Troubleshooting

> **Exam Domain**: Troubleshooting (30%)
> **Related**: [[Troubleshooting Guide]], [[kube-apiserver]], [[etcd]], [[kube-scheduler]], [[kube-controller-manager]], [[kubelet]], [[Static Pods]], [[kubeadm]]

## Overview

Control plane failures are among the most severe cluster issues — they affect all workloads, scheduling, and API access. In kubeadm clusters, all control plane components run as [[Static Pods]] managed by [[kubelet]] on the control-plane node. This means the fix is almost always in one of two places: the **static pod manifest** (`/etc/kubernetes/manifests/`) or the **kubelet** itself. The cluster cannot heal itself when the control plane is broken — you must SSH to the control-plane node and fix it directly.

> [!tip] Exam Tip
> Control plane components are [[Static Pods]] — they are **not** managed by the API server. If `kubectl` is unresponsive, skip it and go straight to `journalctl`, manifest files, and `crictl` on the node.

---

## Control Plane Components and Their Manifest Files

| Component | Manifest Path | What breaks when it fails |
|---|---|---|
| [[kube-apiserver]] | `/etc/kubernetes/manifests/kube-apiserver.yaml` | `kubectl` stops working entirely |
| [[etcd]] | `/etc/kubernetes/manifests/etcd.yaml` | Cluster becomes read-only or unavailable |
| [[kube-scheduler]] | `/etc/kubernetes/manifests/kube-scheduler.yaml` | New Pods stay `Pending` forever |
| [[kube-controller-manager]] | `/etc/kubernetes/manifests/kube-controller-manager.yaml` | Deployments stop reconciling; scaling halts |

---

## Master Diagnostic Workflow

```
1. Can kubectl reach the cluster?      → kubectl cluster-info
2. Are control plane pods running?     → kubectl get pods -n kube-system
3. Are static pod manifests present?   → ls /etc/kubernetes/manifests/
4. Is kubelet healthy on control node? → systemctl status kubelet
5. What do component logs say?         → kubectl logs OR journalctl
6. Are certificates valid?             → kubeadm certs check-expiration
7. Is etcd healthy?                    → etcdctl endpoint health
```

---

## Step 1 — Test API Server Reachability

```bash
# Basic connectivity check
kubectl cluster-info

# If kubectl hangs or refuses connection → API server is down
# Proceed to SSH into the control-plane node
```

> [!warning]
> If `kubectl` is completely unresponsive, **stop using it**. SSH to the control-plane node and work directly from there.

---

## Step 2 — Check Control Plane Pod Status

```bash
# All control plane components should be Running
kubectl get pods -n kube-system

# Expected pods (in a kubeadm cluster):
# etcd-<node>                      Running
# kube-apiserver-<node>            Running
# kube-controller-manager-<node>   Running
# kube-scheduler-<node>            Running

# Describe a failing component pod
kubectl describe pod kube-apiserver-<node> -n kube-system
# Look for: Events section, Exit Code, Reason
```

---

## Step 3 — Check Static Pod Manifests

Control plane pods only exist if their manifest files exist on disk.

```bash
# Verify all 4 manifests are present
ls /etc/kubernetes/manifests/
# etcd.yaml
# kube-apiserver.yaml
# kube-controller-manager.yaml
# kube-scheduler.yaml

# View a manifest to check for errors
cat /etc/kubernetes/manifests/kube-apiserver.yaml
```

### Common Manifest Problems

```bash
# Typo in a flag value (e.g., wrong etcd endpoint)
# Wrong certificate path
# Bad image tag → component won't start
# Missing required flag

# To fix: edit the manifest directly
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# kubelet will detect the change and restart the static pod automatically
```

> [!tip] Exam Tip
> Editing a manifest under `/etc/kubernetes/manifests/` **automatically** restarts the static pod — no manual restart needed. Watch `kubectl get pods -n kube-system` for the pod to come back.

---

## Step 4 — Check kubelet on the Control Plane Node

If static pod manifests exist but pods aren't starting, [[kubelet]] itself may be the problem.

```bash
# Check kubelet service status
systemctl status kubelet

# View last 50 kubelet log lines
journalctl -u kubelet -n 50

# Stream kubelet logs live
journalctl -u kubelet -f

# If kubelet is stopped, start it
systemctl start kubelet
systemctl enable kubelet
```

Common kubelet issues:
- kubelet is stopped (`Active: inactive`)
- kubelet has a config error (bad `--config` path)
- Container runtime (containerd) is down

```bash
# Check container runtime
systemctl status containerd
crictl ps -a    # List all containers including failed ones
```

---

## Step 5 — Read Component Logs

### When kubectl works

```bash
# API server logs
kubectl logs kube-apiserver-<node> -n kube-system

# Scheduler logs
kubectl logs kube-scheduler-<node> -n kube-system

# Controller manager logs
kubectl logs kube-controller-manager-<node> -n kube-system

# etcd logs
kubectl logs etcd-<node> -n kube-system

# Tail last N lines
kubectl logs kube-apiserver-<node> -n kube-system --tail=50
```

### When kubectl is down (API server unreachable)

```bash
# Use journalctl for component logs
journalctl -u kube-apiserver
journalctl -u kube-scheduler
journalctl -u kube-controller-manager
journalctl -u etcd

# Or use crictl to get container logs
crictl ps -a                          # Find container ID
crictl logs <container-id>           # View logs
```

---

## Step 6 — Diagnose by Symptom

### `kubectl` completely unresponsive

**Cause**: [[kube-apiserver]] is down.

```bash
# SSH to control-plane node
ssh controlplane

# Check if API server pod is running
crictl ps -a | grep kube-apiserver

# Check manifest
cat /etc/kubernetes/manifests/kube-apiserver.yaml

# Check logs via journalctl
journalctl -u kube-apiserver -n 100

# Check kubelet
systemctl status kubelet
journalctl -u kubelet -n 50
```

Common causes:
- Bad flag in manifest (e.g., wrong `--etcd-servers` URL)
- Certificate path typo in manifest
- Expired certificates
- etcd is unreachable (API server depends on etcd)

---

### All new Pods stuck in `Pending`

**Cause**: [[kube-scheduler]] is down.

```bash
# Verify scheduler pod is running
kubectl get pods -n kube-system | grep scheduler

# Check logs
kubectl logs kube-scheduler-<node> -n kube-system

# Check manifest
cat /etc/kubernetes/manifests/kube-scheduler.yaml

# Describe for events
kubectl describe pod kube-scheduler-<node> -n kube-system
```

> [!note]
> When the scheduler is down, **existing running Pods are unaffected** — only new Pod placement stops. This narrows the scope quickly.

---

### Deployments not scaling / Pods not being replaced

**Cause**: [[kube-controller-manager]] is down.

```bash
# Verify controller manager pod
kubectl get pods -n kube-system | grep controller-manager

# Check logs
kubectl logs kube-controller-manager-<node> -n kube-system

# Check manifest
cat /etc/kubernetes/manifests/kube-controller-manager.yaml
```

> [!note]
> When the controller manager is down, **already-running Pods keep running**. However, if a Pod dies, no replacement is created. Scaling commands are accepted but nothing happens.

---

### Cluster read-only / API server returning errors

**Cause**: [[etcd]] is down or unhealthy.

```bash
# Check etcd pod
kubectl get pods -n kube-system | grep etcd
kubectl describe pod etcd-<node> -n kube-system

# Check etcd health directly (TLS required)
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Check etcd data directory
ls /var/lib/etcd/

# Check etcd manifest
cat /etc/kubernetes/manifests/etcd.yaml

# Check etcd logs
kubectl logs etcd-<node> -n kube-system
journalctl -u etcd -n 100
```

Common etcd causes:
- Data directory corrupted or wrong path in manifest
- Certificate expiry
- Disk full (`df -h`)
- Wrong `--data-dir` after a restore operation

---

## Step 7 — Check Certificate Expiry

Expired certificates are a common CKA exam scenario — all component communication breaks silently.

```bash
# Check all cert expiration dates
kubeadm certs check-expiration

# Inspect a specific cert manually
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep "Not After"

# Renew all certificates
kubeadm certs renew all

# After renewal — restart static pods by moving manifests out and back in
cd /etc/kubernetes/manifests/
mv kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml .
```

> [!warning]
> After `kubeadm certs renew all`, control plane static pods must be **restarted** to pick up new certs. Moving manifests out of and back into `/etc/kubernetes/manifests/` forces a restart.

---

## Step 8 — Verify etcd Cluster Health (HA Clusters)

```bash
# List etcd members
ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# Check endpoint status (shows leader)
ETCDCTL_API=3 etcdctl endpoint status --write-out=table \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## Quick-Reference: Symptom → Broken Component

| Symptom | Broken Component | First Check |
|---|---|---|
| `kubectl` times out / connection refused | [[kube-apiserver]] | `journalctl -u kubelet` on control node |
| All new Pods stay `Pending` | [[kube-scheduler]] | `kubectl logs kube-scheduler-<node> -n kube-system` |
| Deployments not reconciling / scaling broken | [[kube-controller-manager]] | `kubectl logs kube-controller-manager-<node> -n kube-system` |
| Cluster read-only or API errors | [[etcd]] | `etcdctl endpoint health` |
| Static pods not starting at all | [[kubelet]] | `systemctl status kubelet` |
| All components broken | [[kubelet]] stopped | `systemctl start kubelet` |

---

## Key Commands Summary

```bash
# Cluster reachability
kubectl cluster-info
kubectl get pods -n kube-system

# Static pod manifests
ls /etc/kubernetes/manifests/
vi /etc/kubernetes/manifests/<component>.yaml

# kubelet
systemctl status kubelet
systemctl restart kubelet
journalctl -u kubelet -n 50

# Component logs (when kubectl works)
kubectl logs <component-pod> -n kube-system

# Component logs (when kubectl is down)
journalctl -u kube-apiserver
crictl ps -a
crictl logs <container-id>

# Certificates
kubeadm certs check-expiration
kubeadm certs renew all

# etcd health
ETCDCTL_API=3 etcdctl endpoint health \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key
```

---

## Related Notes

- [[Troubleshooting Guide]] — Master diagnostic workflow for all cluster issues
- [[kube-apiserver]] — Entry point; everything depends on it
- [[etcd]] — Source of truth; loss means cluster amnesia
- [[kube-scheduler]] — Assigns Pods to nodes
- [[kube-controller-manager]] — Reconciles desired vs actual state
- [[Static Pods]] — How control plane components are deployed and restarted
- [[kubelet]] — Manages static pods on the control-plane node
- [[kubeadm]] — Certificate management and cluster upgrades
- [[Backup]] — etcd snapshot restore as a recovery mechanism
- [[Node Troubleshooting]] — When the control-plane node itself is the problem

---

## Key Mental Model

Control plane troubleshooting has one guiding rule: **follow the dependency chain downward**. Every component depends on [[kubelet]] to be running, every component depends on [[kube-apiserver]] to communicate, and the API server depends on [[etcd]] for state. If kubectl works, use it. If it doesn't, drop to the node and use `journalctl`, manifest files, and `crictl`. The fix is almost always a **wrong path, a bad flag, an expired cert, or a stopped service** — never a mystery.
