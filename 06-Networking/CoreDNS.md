---
tags: [cka/networking, networking, cka/architecture]
aliases: [CoreDNS, Cluster DNS, kube-dns, DNS resolution, Service Discovery]
---

# CoreDNS

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Services]], [[Pods]], [[Namespaces]], [[Network Policy]], [[Addons]], [[kubelet]]

## Overview

**CoreDNS** is the cluster-internal DNS server installed automatically by [[kubeadm]]. It runs as a [[Deployments|Deployment]] in `kube-system` and gives every [[Services|Service]] a stable DNS name. Without CoreDNS, Pods cannot resolve Service names — they would need to hard-code ClusterIPs instead. Every Pod in the cluster is automatically configured to use CoreDNS as its DNS resolver via `/etc/resolv.conf`.

---

## How CoreDNS Works

```
Pod → /etc/resolv.conf → CoreDNS ClusterIP → Service name → ClusterIP
```

1. A Pod is created — [[kubelet]] injects `nameserver <CoreDNS-ClusterIP>` into `/etc/resolv.conf`
2. Pod makes a DNS query (e.g. `my-service.default.svc.cluster.local`)
3. CoreDNS receives the query, looks up the [[Services|Service]] in cluster state
4. CoreDNS returns the Service's ClusterIP
5. Pod connects directly to that ClusterIP

---

## DNS Name Format

### Services

```
<service-name>.<namespace>.svc.cluster.local
```

| Scope | Format | Example |
|---|---|---|
| Same namespace | `<service>` | `backend` |
| Cross-namespace (short) | `<service>.<namespace>` | `backend.prod` |
| Full FQDN | `<service>.<namespace>.svc.cluster.local` | `backend.prod.svc.cluster.local` |

### Pods

Pod DNS records exist but are rarely used directly:

```
<pod-ip-dashes>.<namespace>.pod.cluster.local
# e.g. 10-244-1-5.default.pod.cluster.local
```

> [!tip] Exam Tip
> Always use the **Service DNS name**, not the Pod IP. Pod IPs are ephemeral — Service DNS is stable.

---

## CoreDNS Architecture

CoreDNS runs as a **Deployment** (typically 2 replicas for HA) exposed via a **Service** named `kube-dns`:

```
┌─────────────────────────────────────────┐
│              kube-system                │
│                                         │
│  Deployment: coredns (2 replicas)       │
│       ↑                                 │
│  Service: kube-dns (ClusterIP: 10.x.x)  │
└─────────────────────────────────────────┘
         ↑ all pods resolve DNS here
```

> [!note]
> The Service is named `kube-dns` for historical reasons (CoreDNS replaced kube-dns). The label selector is `k8s-app=kube-dns`.

---

## Corefile — CoreDNS Configuration

CoreDNS behavior is controlled by a **Corefile** stored in a [[ConfigMap]]:

```bash
kubectl get configmap coredns -n kube-system -o yaml
```

Default Corefile:

```
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30
    loop
    reload
    loadbalance
}
```

Key plugins:

| Plugin | Purpose |
|---|---|
| `kubernetes` | Resolves cluster-internal names (Services, Pods) |
| `forward` | Forwards external queries to upstream DNS |
| `cache` | Caches DNS responses (default 30s TTL) |
| `errors` | Logs DNS errors |
| `health` | Health check endpoint at `:8080/health` |
| `ready` | Readiness endpoint at `:8181/ready` |

> [!tip] Exam Tip
> To customize DNS (e.g. add a stub zone or rewrite), you edit the `coredns` ConfigMap — not a static file. Changes take effect after a CoreDNS rollout restart.

---

## Customising CoreDNS

### Add a Stub Zone (forward specific domain to external DNS)

```yaml
# kubectl edit configmap coredns -n kube-system
data:
  Corefile: |
    .:53 {
        # ... existing config ...
        forward . /etc/resolv.conf
    }
    example.internal:53 {
        forward . 192.168.1.10   # Custom DNS server for this domain
    }
```

### Rewrite a DNS name

```
rewrite name myapp.example.com myapp.default.svc.cluster.local
```

After editing the ConfigMap, restart CoreDNS:

```bash
kubectl rollout restart deployment coredns -n kube-system
```

---

## Pod DNS Policy

Each Pod's DNS behaviour is controlled by `dnsPolicy` in the Pod spec:

| Policy | Behaviour |
|---|---|
| `ClusterFirst` (default) | Use CoreDNS; fall back to upstream for external names |
| `ClusterFirstWithHostNet` | Same as ClusterFirst but for hostNetwork Pods |
| `Default` | Inherit the node's DNS settings (NOT cluster DNS) |
| `None` | Ignore all defaults; must specify `dnsConfig` manually |

```yaml
spec:
  dnsPolicy: ClusterFirst       # default — almost always correct
  dnsConfig:                    # optional extra config
    nameservers:
      - 1.1.1.1
    searches:
      - my-custom.search.domain
    options:
      - name: ndots
        value: "5"
```

---

## Key Commands

```bash
# Check CoreDNS pods are running
kubectl get pods -n kube-system -l k8s-app=kube-dns

# Check CoreDNS deployment
kubectl get deployment coredns -n kube-system

# View CoreDNS ConfigMap (Corefile)
kubectl get configmap coredns -n kube-system -o yaml

# Check CoreDNS logs (look for SERVFAIL, errors)
kubectl logs -n kube-system -l k8s-app=kube-dns

# Check the kube-dns Service (this is the ClusterIP Pods use)
kubectl get svc kube-dns -n kube-system

# Test DNS resolution from inside cluster
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup kubernetes
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- nslookup my-service.default.svc.cluster.local

# Check /etc/resolv.conf inside a Pod
kubectl exec -it <pod> -- cat /etc/resolv.conf

# Restart CoreDNS after ConfigMap changes
kubectl rollout restart deployment coredns -n kube-system

# Check CoreDNS endpoints
kubectl get endpoints kube-dns -n kube-system
```

> [!tip] Exam Tip
> Use `busybox:1.28` for DNS tests — newer busybox versions have a broken `nslookup`. Alternatively use `nicolaka/netshoot` for a full networking toolkit.

---

## Common Issues / Troubleshooting

- **DNS not resolving inside Pod** → check CoreDNS pods are Running: `kubectl get pods -n kube-system -l k8s-app=kube-dns`
- **`nslookup kubernetes` fails** → CoreDNS is down or kube-dns Service has no endpoints; check `kubectl get endpoints kube-dns -n kube-system`
- **SERVFAIL for external names** → `forward` plugin can't reach upstream DNS; check node DNS config
- **Intermittent DNS timeouts** → `ndots:5` causes many search-domain lookups; tune with `dnsConfig`
- **Custom stub zone not working** → ConfigMap edited but CoreDNS not restarted; run `kubectl rollout restart deployment coredns -n kube-system`
- **Pod using wrong DNS** → `dnsPolicy: Default` set instead of `ClusterFirst`; Pod resolves via node DNS, not CoreDNS
- **CoreDNS CrashLoopBackOff** → check logs with `kubectl logs`; often a Corefile syntax error after manual edit
- **`/etc/resolv.conf` in Pod shows wrong nameserver** → node-level DNS issue; check kubelet config

---

## Related Notes

- [[Services]] — Every Service gets a DNS A record managed by CoreDNS
- [[Namespaces]] — DNS names include namespace: `<svc>.<ns>.svc.cluster.local`
- [[Pods]] — Each Pod's `/etc/resolv.conf` points to CoreDNS automatically
- [[kubelet]] — Injects DNS config into each Pod at creation time
- [[Addons]] — CoreDNS is a required cluster addon installed by kubeadm
- [[Network Policy]] — Can block DNS traffic (UDP/TCP port 53) if misconfigured — always allow egress to kube-dns
- [[Troubleshooting Guide]] — DNS failures are a common networking troubleshooting scenario

---

## Key Mental Model

CoreDNS is the **phone book of the cluster**. You know the name (`my-service`), CoreDNS gives you the number (ClusterIP). Without it, every Pod would need to hard-code IP addresses — and IPs change when Services are recreated. CoreDNS makes the cluster location-independent: names stay stable even when everything underneath moves.
