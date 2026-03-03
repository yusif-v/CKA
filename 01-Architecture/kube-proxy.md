---
tags: [cka/architecture, cka/networking, architecture, networking]
aliases: [kube proxy, Network Proxy]
---

# kube-proxy

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Services]], [[Cluster Architecture]], [[kubelet]], [[Network Policy]]

## Overview

**kube-proxy** is a network component that runs on every Node and implements the [[Services]] abstraction. It watches [[kube-apiserver]] for Service and Endpoint changes, then programs **iptables or IPVS rules** on the Node to route traffic from Service virtual IPs to the actual Pod IPs.

kube-proxy does not handle Pod-to-Pod traffic — that is the CNI plugin's job.

## What kube-proxy Does

- Watches Service and Endpoint objects via [[kube-apiserver]]
- Programs networking rules (iptables/IPVS) on each Node
- Implements load balancing across Pod backends
- Enables stable virtual IPs (ClusterIP) for Services

## Proxy Modes

| Mode | Description | Default |
|---|---|---|
| `iptables` | Uses netfilter rules; most common | Yes (most clusters) |
| `ipvs` | Uses Linux IPVS; better performance at scale | Opt-in |
| `nftables` | Newer Linux netfilter; some distros | Emerging |

## How Service Routing Works

```
Client Pod → ClusterIP (virtual) → iptables/IPVS rule → Real Pod IP
```

kube-proxy programs these rules so traffic sent to a Service's ClusterIP is transparently forwarded to a healthy Pod backend.

## Deployment

kube-proxy runs as a [[DaemonSets|DaemonSet]] in `kube-system`:

```bash
kubectl get daemonset kube-proxy -n kube-system
```

Configuration is stored in a [[ConfigMap]]:

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml
```

## Key Commands

```bash
# Check kube-proxy pods (one per node)
kubectl get pods -n kube-system -l k8s-app=kube-proxy

# View kube-proxy logs
kubectl logs -n kube-system -l k8s-app=kube-proxy

# Check iptables rules (on node)
iptables -t nat -L KUBE-SERVICES -n

# Verify service endpoints
kubectl get endpoints <service-name>
```

## Common Issues / Troubleshooting

- **Service not reachable** → check kube-proxy pod is running on the node
- **No endpoints** → [[Services]] selector doesn't match [[Pods]] labels; `kubectl get endpoints`
- **iptables rules not updated** → kube-proxy may be down or restarting
- **IPVS mode issues** → verify IPVS kernel modules are loaded on nodes

## Related Notes

- [[Services]] — What kube-proxy implements
- [[Cluster Architecture]] — kube-proxy in context
- [[Network Policy]] — Network Policy is enforced by CNI, not kube-proxy
- [[DaemonSets]] — kube-proxy runs as a DaemonSet

## Key Mental Model

kube-proxy is the **traffic director** at every Node's intersection. It doesn't carry the traffic itself — it just programs the road signs (iptables rules) so that traffic aimed at a Service's virtual address automatically finds its way to a real Pod.
