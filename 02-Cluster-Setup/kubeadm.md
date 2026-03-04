---
tags: [cka/architecture, architecture, cli]
aliases: [kubeadm init, kubeadm join, cluster bootstrap]
---
# kubeadm

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%) **Related**: [[kube-apiserver]], [[etcd]], [[kubelet]], [[Static Pods]], [[Kubeconfig]], [[TLS in Kubernetes]], [[OS Upgrade]]

## Overview

**kubeadm** is the official Kubernetes tool for **bootstrapping production-grade clusters** in a standardized, repeatable way. It handles control plane initialization, node joining, certificate generation, and component configuration — but it does not install networking or manage workloads.

> [!tip] Exam Tip `kubeadm upgrade` and `kubeadm certs` commands are **heavily tested**. Know the full upgrade sequence and certificate renewal flow cold.

## What kubeadm Does and Does NOT Do

|Does ✅|Does NOT ❌|
|---|---|
|Initialize the control plane|Install CNI networking|
|Generate TLS certificates in `/etc/kubernetes/pki/`|Manage workloads|
|Create [[Static Pods]] manifests for control plane|Upgrade OS packages|
|Configure [[kubelet]]|Provide a cluster UI|
|Create [[Kubeconfig]] files|Install `kubectl` or `kubelet`|
|Join worker nodes to the cluster||

---

## Cluster Bootstrap Flow

```
1. Install container runtime (containerd)
2. Install kubelet, kubeadm, kubectl
3. kubeadm init  →  control plane up
4. Copy kubeconfig  →  kubectl works
5. Install CNI plugin  →  networking up
6. kubeadm join  →  worker nodes join
```

---

## Control Plane Initialization

```bash
# Basic init
kubeadm init

# With pod network CIDR (required for most CNI plugins)
kubeadm init --pod-network-cidr=10.244.0.0/16

# With specific API server address
kubeadm init \
  --apiserver-advertise-address=<node-ip> \
  --pod-network-cidr=10.244.0.0/16
```

After init, configure kubectl access:

```bash
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

> [!tip] Exam Tip Always run the three `mkdir/cp/chown` commands after `kubeadm init` — without them, `kubectl` will refuse connection.

---

## Installing a CNI Plugin

kubeadm **does not install networking**. Without a CNI plugin, all Pods stay `Pending`.

```bash
# Flannel
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Verify CNI is running
kubectl get pods -n kube-system
```

---

## Joining Worker Nodes

```bash
# Use the join command printed after kubeadm init
kubeadm join <control-plane-ip>:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash>

# Token expires after 24h — regenerate if needed
kubeadm token create --print-join-command
```

---

## Kubernetes Version Upgrade

> [!tip] Exam Tip The upgrade sequence is tested directly. Always upgrade the control plane first, then worker nodes one by one.

### Step 1 — Upgrade kubeadm (on control plane node)

```bash
# Check available versions
kubeadm upgrade plan

# Upgrade kubeadm binary first (via OS package manager)
apt-get update && apt-get install -y kubeadm=1.30.0-00

# Apply the upgrade
kubeadm upgrade apply v1.30.0
```

### Step 2 — Drain and Upgrade kubelet (control plane node)

```bash
kubectl drain <control-plane-node> --ignore-daemonsets

# Upgrade kubelet and kubectl
apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00

systemctl daemon-reload
systemctl restart kubelet

kubectl uncordon <control-plane-node>
```

### Step 3 — Upgrade Worker Nodes (repeat per node)

```bash
# On each worker node
apt-get install -y kubeadm=1.30.0-00
kubeadm upgrade node

# Drain from control plane
kubectl drain <worker-node> --ignore-daemonsets --delete-emptydir-data

# On the worker node
apt-get install -y kubelet=1.30.0-00 kubectl=1.30.0-00
systemctl daemon-reload
systemctl restart kubelet

# Uncordon from control plane
kubectl uncordon <worker-node>
```

---

## Certificate Management

```bash
# Check all certificate expiration dates
kubeadm certs check-expiration

# Renew all certificates at once
kubeadm certs renew all

# Renew a specific certificate
kubeadm certs renew apiserver
```

> [!warning] After renewing certificates, restart the control plane [[Static Pods]] by moving their manifests out of and back into `/etc/kubernetes/manifests/`.

---

## Resetting a Node

```bash
# Remove all kubeadm state from the node
kubeadm reset

# Clean up CNI files manually (kubeadm reset does NOT do this)
rm -rf /etc/cni/net.d

# Also flush iptables if needed
iptables -F && iptables -t nat -F
```

---

## Files Created by kubeadm

|Path|Purpose|
|---|---|
|`/etc/kubernetes/manifests/`|[[Static Pods]] for control plane components|
|`/etc/kubernetes/pki/`|All TLS certificates and keys|
|`/etc/kubernetes/admin.conf`|Admin [[Kubeconfig]]|
|`/etc/kubernetes/kubelet.conf`|kubelet → apiserver auth|
|`/var/lib/kubelet/config.yaml`|kubelet configuration|

---

## Key Commands

```bash
# Initialize control plane
kubeadm init --pod-network-cidr=10.244.0.0/16

# Print join command for workers
kubeadm token create --print-join-command

# Check upgrade path
kubeadm upgrade plan

# Apply upgrade
kubeadm upgrade apply v1.30.0

# Upgrade worker node config
kubeadm upgrade node

# Check certificate expiry
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Reset a node
kubeadm reset
```

---

## Common Issues / Troubleshooting

|Issue|Cause|Fix|
|---|---|---|
|Pods stuck `Pending` after init|CNI not installed|`kubectl apply` a CNI manifest|
|Worker node can't join|Token expired (24h TTL)|`kubeadm token create --print-join-command`|
|`kubectl` connection refused|admin.conf not copied|Run the three `mkdir/cp/chown` commands|
|Certificate errors on components|Certs expired|`kubeadm certs renew all`, restart static Pods|
|Node stuck after upgrade|kubelet not restarted|`systemctl daemon-reload && systemctl restart kubelet`|

---

## Related Notes

- [[Static Pods]] — kubeadm creates these to run the control plane
- [[Kubeconfig]] — kubeadm generates `admin.conf` during init
- [[etcd]] — kubeadm configures and bootstraps etcd as a static Pod
- [[TLS in Kubernetes]] — kubeadm manages the full cluster PKI
- [[OS Upgrade]] — Node drain/upgrade sequence pairs with kubeadm upgrade

---

## Key Mental Model

kubeadm is the **midwife of Kubernetes clusters**. It doesn't raise the cluster or manage its daily life — it ensures the birth is **clean, secure, and repeatable**. Once `init` is done, hand the cluster off to `kubectl` and your CNI of choice.