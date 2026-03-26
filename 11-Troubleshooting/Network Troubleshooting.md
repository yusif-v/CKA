---
tags: [cka/troubleshooting, cka/networking, troubleshooting, networking]
aliases: [Network Debug, DNS Troubleshooting, Service Connectivity, Endpoint Debugging]
---

# Network Troubleshooting

> **Exam Domain**: Troubleshooting (30%) · Services & Networking (20%)
> **Related**: [[Troubleshooting Guide]], [[Services]], [[Network Policy]], [[CoreDNS]], [[kube-proxy]], [[CNI Plugins]], [[Pods]], [[Namespaces]], [[Ingress]]

## Overview

Network troubleshooting covers diagnosing why Pods can't reach [[Services]], why DNS fails inside the cluster, why cross-namespace traffic is blocked, and why [[Ingress]] rules don't route correctly. Most cluster network issues trace back to one of four layers: **Service selector mismatch**, **DNS failure**, **NetworkPolicy blocking**, or **CNI/kube-proxy not running**.

> [!tip] Exam Tip
> Empty endpoints (`kubectl get endpoints <svc>`) is the single most common networking exam finding. Always check endpoints before anything else.

---

## Step-by-Step Network Diagnosis

### Step 1: Check the Service and Its Endpoints

```bash
# Is the Service defined correctly?
kubectl get svc <service> -n <namespace>
kubectl describe svc <service> -n <namespace>
# Look for: Selector field, Port/TargetPort mapping

# CRITICAL — Are there any endpoints?
kubectl get endpoints <service> -n <namespace>
# Empty endpoints = no Pods match the selector → selector mismatch
```

Empty endpoints is the **most common cause** of Service unreachability. If `Endpoints: <none>`, the Service selector does not match any running Pod labels.

Fix:
```bash
# Check what labels Pods actually have
kubectl get pods -n <namespace> --show-labels

# Check what the Service selector expects
kubectl describe svc <service> -n <namespace> | grep Selector

# Fix: either update the Service selector or the Pod labels
```

### Step 2: Test DNS Resolution

DNS failure appears as connection timeouts or "Name or service not known" errors inside a Pod.

```bash
# Spawn a debug pod and test DNS
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes

# Test a specific service
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup <service>.<namespace>.svc.cluster.local

# Short form (same namespace)
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup <service>
```

> [!note]
> Use `busybox:1.28` — newer busybox versions have a broken `nslookup`. Alternatively use `nicolaka/netshoot`.

If DNS fails, check [[CoreDNS]]:

```bash
# Are CoreDNS pods running?
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Are CoreDNS endpoints populated?
kubectl get endpoints kube-dns -n kube-system

# CoreDNS logs — look for SERVFAIL, errors
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check /etc/resolv.conf inside the affected Pod
kubectl exec -it <pod> -n <namespace> -- cat /etc/resolv.conf
# nameserver should point to CoreDNS ClusterIP
```

### Step 3: Test Service Connectivity Directly

```bash
# Test HTTP from within the cluster
kubectl run conn-test --image=busybox:1.28 --rm -it --restart=Never \
  -- wget -qO- http://<service>:<port>

# Test TCP reachability
kubectl run conn-test --image=busybox:1.28 --rm -it --restart=Never \
  -- nc -zv <service> <port>

# curl version (if you prefer)
kubectl run conn-test --image=curlimages/curl --rm -it --restart=Never \
  -- curl -v http://<service>.<namespace>:<port>
```

### Step 4: Test Pod-to-Pod Connectivity Directly

Bypasses the Service layer to isolate whether the issue is at the Service level or the Pod/CNI level:

```bash
# Get the Pod IP
kubectl get pod <pod> -n <namespace> -o wide

# From another Pod, test directly
kubectl exec -it <other-pod> -n <namespace> -- wget -qO- http://<pod-ip>:<port>
kubectl exec -it <other-pod> -- ping <pod-ip>
```

If Pod-to-Pod works but Service doesn't → **Service/kube-proxy issue**.
If Pod-to-Pod fails → **CNI issue** or **NetworkPolicy blocking**.

### Step 5: Check kube-proxy

[[kube-proxy]] programs iptables/IPVS rules that implement Service routing. If it's down, Services stop working.

```bash
# Is kube-proxy running on every node?
kubectl get pods -n kube-system -l k8s-app=kube-proxy -o wide

# kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Verify iptables rules exist on a node (SSH to node)
iptables -t nat -L KUBE-SERVICES -n
iptables -t nat -L KUBE-SVC-<hash> -n

# IPVS mode
ipvsadm -Ln
```

### Step 6: Check for NetworkPolicy Blocking

[[Network Policy]] silently drops traffic that doesn't match an allow rule. If NetworkPolicy exists in a namespace, **all unmatched traffic is denied**.

```bash
# List NetworkPolicies in the namespace
kubectl get networkpolicy -n <namespace>

# Describe a policy — see what it allows
kubectl describe networkpolicy <policy> -n <namespace>

# Check if the namespace has any NetworkPolicies at all
kubectl get networkpolicy -A
```

> [!warning]
> If you apply an **egress** NetworkPolicy without explicitly allowing DNS (UDP/TCP port 53 to kube-system), Pods will lose DNS resolution immediately. Always include a DNS egress rule.

```yaml
# Egress allow for DNS — always include this when writing egress policies
egress:
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
  ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
```

### Step 7: Check the CNI Plugin

If Pods have no IP addresses or can't reach each other at all, the [[CNI Plugins|CNI plugin]] may be broken.

```bash
# Check CNI pods are running
kubectl get pods -n kube-system | grep -E "calico|flannel|cilium|weave"

# Pods should all have IPs
kubectl get pods -A -o wide | grep '<none>'

# CNI config on node (SSH to node)
ls /etc/cni/net.d/
cat /etc/cni/net.d/*.conf*

# CNI logs
kubectl logs -n kube-system <cni-pod-name>
```

---

## Diagnosing by Symptom

### Service Unreachable (connection refused or timeout)

```bash
kubectl get endpoints <svc> -n <ns>   # Empty? → selector mismatch
kubectl describe svc <svc> -n <ns>    # Check Selector vs Pod labels
kubectl get pods -l <selector> -n <ns> --show-labels  # Verify labels
```

### DNS Not Resolving

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns  # CoreDNS running?
kubectl get endpoints kube-dns -n kube-system         # Has endpoints?
kubectl logs -n kube-system -l k8s-app=kube-dns       # Errors?
kubectl exec -it <pod> -- cat /etc/resolv.conf        # Points to CoreDNS?
```

### Traffic Blocked (times out, no connection refused)

```bash
kubectl get networkpolicy -n <namespace>   # Any policies present?
kubectl describe networkpolicy -n <namespace>  # What traffic is allowed?
# Test with policy temporarily removed (if safe to do in exam environment)
```

### Cross-Namespace Traffic Failing

```bash
# Use full FQDN for cross-namespace
# From ns-a, reaching a service in ns-b:
wget http://<service>.ns-b.svc.cluster.local

# Check if namespaceSelector in NetworkPolicy uses correct label
kubectl get namespace ns-b --show-labels
```

### Ingress Not Routing

```bash
# Is an Ingress Controller installed?
kubectl get pods -n ingress-nginx   # or wherever controller runs

# Is the Ingress resource correct?
kubectl describe ingress <ingress> -n <namespace>
# Check: Rules, Backend service name, port, ingressClassName

# Is the backend Service reachable?
kubectl get endpoints <backend-svc> -n <namespace>

# Controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

### Pod Has No IP Address

```bash
# CNI not running or misconfigured
kubectl get pods -n kube-system | grep -E "cni|calico|flannel|cilium"
kubectl logs -n kube-system <cni-pod>

# Check CNI config on the node
# SSH to node:
ls /etc/cni/net.d/
ls /opt/cni/bin/
```

---

## Key Commands Summary

```bash
# --- Service & Endpoints ---
kubectl get svc -n <namespace>
kubectl describe svc <service> -n <namespace>
kubectl get endpoints <service> -n <namespace>

# --- DNS ---
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup <svc>.<ns>.svc.cluster.local
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# --- Connectivity ---
kubectl run test --image=busybox:1.28 --rm -it --restart=Never -- wget -qO- http://<service>:<port>
kubectl run test --image=busybox:1.28 --rm -it --restart=Never -- nc -zv <service> <port>
kubectl exec -it <pod> -- ping <pod-ip>

# --- NetworkPolicy ---
kubectl get networkpolicy -n <namespace>
kubectl describe networkpolicy -n <namespace>

# --- kube-proxy ---
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy

# --- CNI ---
kubectl get pods -A | grep -E "calico|flannel|cilium|weave"
kubectl get pods -A -o wide    # Check all Pods have IPs

# --- Ingress ---
kubectl get ingress -A
kubectl describe ingress <ingress> -n <namespace>
kubectl get pods -n ingress-nginx
```

---

## Common Issues Quick Reference

| Symptom | Likely Cause | Diagnosis | Fix |
|---|---|---|---|
| Service unreachable | Empty endpoints / selector mismatch | `kubectl get endpoints <svc>` | Fix Service selector or Pod labels |
| DNS resolution fails | CoreDNS down | `kubectl get pods -n kube-system -l k8s-app=kube-dns` | Restart CoreDNS deployment |
| Traffic silently dropped | NetworkPolicy blocking | `kubectl get networkpolicy -n <ns>` | Add allow rule or fix selector |
| DNS breaks after egress policy | Missing DNS allow rule | Check egress policy for port 53 | Add DNS egress rule |
| Cross-namespace DNS fails | Using short name instead of FQDN | Test with `<svc>.<ns>.svc.cluster.local` | Use full FQDN |
| Pod has no IP | CNI not installed or broken | `kubectl get pods -n kube-system \| grep cni` | Install or fix CNI plugin |
| Service exists but kube-proxy broken | kube-proxy pod down | `kubectl get pods -n kube-system -l k8s-app=kube-proxy` | Restart kube-proxy DaemonSet |
| Ingress returns 404 | Wrong pathType or backend service | `kubectl describe ingress` | Fix path, targetPort, or Service |
| Ingress does nothing | No Ingress Controller installed | `kubectl get pods -n ingress-nginx` | Install an Ingress Controller |
| NetworkPolicy not enforced | CNI doesn't support it (Flannel) | Check which CNI is in use | Switch to Calico or Cilium |

---

## Network Troubleshooting Decision Tree

```
Can the Pod reach the Service?
  ├── NO
  │   ├── Check endpoints → empty?
  │   │     └── YES → selector mismatch → fix labels
  │   ├── Endpoints exist → can Pod reach Pod IP directly?
  │   │     ├── YES → kube-proxy issue → check kube-proxy pods
  │   │     └── NO  → CNI issue or NetworkPolicy
  │   │               ├── NetworkPolicy present? → check allow rules
  │   │               └── No policy → check CNI pods and logs
  │   └── DNS failing → CoreDNS down → restart CoreDNS deployment
  └── YES but slow or intermittent
        ├── Check Pod readiness probes (Pod Ready?)
        ├── Check for NetworkPolicy with rate-limiting effects
        └── Check kube-proxy logs for sync errors
```

---

## Related Notes

- [[Troubleshooting Guide]] — Master workflow; network is one of the five key layers
- [[Services]] — Service types, selector mechanics, and endpoint verification
- [[CoreDNS]] — Cluster DNS server; Corefile config and DNS troubleshooting
- [[kube-proxy]] — Implements Service routing via iptables/IPVS on each node
- [[Network Policy]] — CNI-enforced firewall; silent drops require explicit allow rules
- [[CNI Plugins]] — Pod networking layer; must be installed and healthy for any networking to work
- [[Ingress]] — HTTP/HTTPS routing; requires a controller to function
- [[Namespaces]] — DNS names are namespace-scoped; cross-namespace needs full FQDN
- [[Pod Troubleshooting]] — Pod-level issues that surface as apparent network failures

---

## Key Mental Model

Cluster networking is a **layered stack**. When traffic fails, work from the outside in: **Service → Endpoints → DNS → kube-proxy → NetworkPolicy → CNI**. Each layer can fail independently. The most common failure is the first one — a Service selector that doesn't match any Pod labels. If the endpoint list is empty, no amount of CNI or DNS debugging will help. **Check endpoints first, every time.**
