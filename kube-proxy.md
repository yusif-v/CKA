#architecture
# kube-proxy
## Overview

**kube-proxy** is a **networking component** that runs on every node and implements **Service networking** in Kubernetes.

It ensures traffic sent to a **Service IP** is forwarded to the correct **Pod backends**.

Without kube-proxy, Services do not work.

## Role in Kubernetes

kube-proxy handles:
- Service → Pod routing
- Load balancing across Pods
- Session affinity (if configured)

It does **not** route Pod-to-Pod traffic directly — that’s handled by the **CNI plugin**.

🔗 Related:
- [[Services]]
- [[CNI]]
- [[kube-apiserver]]

## How kube-proxy Works

1. Watches the Kubernetes API for Services & Endpoints
2. Programs node networking rules
3. Redirects traffic to healthy Pods

Traffic flow:

```bash
Client → Service IP → kube-proxy → Pod
```

## Modes of Operation
### iptables (Default)

- Uses Linux iptables
- Fast and widely supported
- Rules grow with number of Services

### IPVS

- Uses Linux IPVS
- Better performance at scale
- Requires IPVS kernel modules

Check mode:

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml
```

## kube-proxy as a DaemonSet

- Runs on **every node**
- Managed as a **DaemonSet**
- Deployed in kube-system

```bash
kubectl get daemonset kube-proxy -n kube-system
```

🔗 Related:
- [[Daemonsets]]

## Service Types Handled

kube-proxy supports:
- ClusterIP
- NodePort
- LoadBalancer (node-level routing)

🔗 Related:
- [[Services]]

## Observability & Debugging

Check Pod:

```bash
kubectl get pods -n kube-system -l k8s-app=kube-proxy
```

Logs:

```bash
kubectl logs -n kube-system kube-proxy-<node-name>
```

## Common Issues

- Services not reachable
- Incorrect iptables rules
- kube-proxy crash looping
- IPVS modules missing

## Best Practices

- Use IPVS for large clusters
- Avoid excessive Services
- Monitor kube-proxy CPU usage
- Keep kernel modules up to date

## Key Mental Model

kube-proxy is the **traffic director** of the cluster.

Pods speak freely,
nodes are roads,
and Services are **published addresses**.

kube-proxy makes sure every request reaches a live backend —
quietly, constantly, and without applause.