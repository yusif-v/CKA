---
tags: [cka/networking, networking]
aliases: [Ingress Controller, HTTP routing, L7 routing]
---

# Ingress

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Services]], [[Network Policy]], [[Namespaces]], [[TLS in Kubernetes]]

## Overview

**Ingress** is a Kubernetes resource that manages **external HTTP/HTTPS access** to [[Services]] inside the cluster. It acts as a smart entry point providing host/path-based routing, load balancing, and SSL/TLS termination — all through a **single external IP**.

> [!important]
> Ingress requires an **Ingress Controller** to function. Without one, Ingress resources do nothing.

## How Ingress Works

```
Client → Ingress Controller (Nginx/HAProxy) → Ingress Rules → Service → Pod
```

Two components:
1. **Ingress Resource** — Kubernetes object defining routing rules (what you create)
2. **Ingress Controller** — Reverse proxy that reads rules and routes traffic (must be installed)

## Basic Ingress Resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## Path-Based Routing

Route different paths to different services:

```yaml
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## Host-Based Routing

Route different domains to different services:

```yaml
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-service
            port:
              number: 80
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

## TLS Configuration (HTTPS)

```yaml
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: my-tls-secret   # Must be kubernetes.io/tls type Secret

  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

Create TLS Secret:

```bash
kubectl create secret tls my-tls-secret \
  --cert=cert.crt \
  --key=key.key
```

## Path Types

| PathType | Behavior |
|---|---|
| `Prefix` | Matches any path starting with the prefix |
| `Exact` | Exact path match only |
| `ImplementationSpecific` | Behavior depends on Ingress Controller |

## Ingress vs LoadBalancer Service

| Feature | Ingress | LoadBalancer Service |
|---|---|---|
| OSI Layer | L7 (HTTP/HTTPS) | L4 (TCP/UDP) |
| Routing | Host/path-based | No routing |
| TLS termination | ✅ Yes | Manual |
| IPs used | One for many apps | One per Service |

## Key Commands

```bash
# List Ingress resources
kubectl get ingress
kubectl get ingress -A

# Describe Ingress
kubectl describe ingress web-ingress

# Check Ingress Controller (nginx example)
kubectl get pods -n ingress-nginx

# View controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx
```

## Common Issues / Troubleshooting

- **Ingress does nothing** → Ingress Controller not installed or no `ingressClassName`
- **404 from Ingress** → backend Service doesn't exist or selector wrong; check Service
- **TLS not working** → Secret doesn't exist or wrong type; check `kubectl get secret`
- **Path not matching** → wrong pathType; try `Prefix` instead of `Exact`
- **Host-based routing broken** → Host header must match exactly; check DNS or `/etc/hosts`

## Related Notes

- [[Services]] — Ingress routes to Services, not directly to Pods
- [[TLS in Kubernetes]] — TLS Secrets used for HTTPS termination
- [[Network Policy]] — May block traffic between Ingress Controller and Services
- [[Namespaces]] — Ingress and its backend Services should be in same namespace

## Key Mental Model

Ingress is the **concierge** at the front door of your cluster. One door, many destinations. It reads the routing rules you define and directs each visitor (HTTP request) to the right room (Service), handling TLS check-in at the entrance.
