---
tags: [cka/networking, networking]
aliases: [Gateway API, GatewayClass, HTTPRoute, Kubernetes Gateway]
---

# Gateway API

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[Ingress]], [[Services]], [[TLS in Kubernetes]], [[Network Policy]], [[Custom Resource Definition]]

## Overview

The **Gateway API** is the official Kubernetes successor to [[Ingress]]. It provides more expressive, role-oriented, and extensible traffic management for HTTP, HTTPS, TCP, and gRPC traffic. Unlike [[Ingress]], it separates concerns between **infrastructure owners** (who manage the Gateway) and **application teams** (who manage routing rules).

> [!tip] Exam Tip
> Gateway API resources are **CRDs** — they must be installed separately. If `kubectl get gateway` returns "no resources found", the CRDs are not installed yet.

## Gateway API vs Ingress

| Feature | Ingress | Gateway API |
|---|---|---|
| Protocols | HTTP/HTTPS only | HTTP, HTTPS, TCP, gRPC |
| Traffic splitting | ❌ | ✅ |
| Role separation | ❌ | ✅ (infra vs app team) |
| Header manipulation | Limited | ✅ |
| Resource type | Built-in | CRDs |
| Status | Current standard | Official successor |

## Core Resources

```
GatewayClass → Gateway → HTTPRoute / TCPRoute / GRPCRoute
```

| Resource | Owner | Role |
|---|---|---|
| `GatewayClass` | Infra team | Defines the controller type (like IngressClass) |
| `Gateway` | Infra team | Defines the listener — port, protocol, TLS |
| `HTTPRoute` | App team | Defines routing rules to backend Services |
| `TCPRoute` | App team | TCP-level routing |
| `GRPCRoute` | App team | gRPC-specific routing |

## Traffic Flow

```
Client → Gateway (Listener) → HTTPRoute rules → Service → Pod
```

Compare to [[Ingress]]:
```
Client → Ingress Controller → Ingress rules → Service → Pod
```

## GatewayClass

Defines which controller implements the Gateway — equivalent to `IngressClass` in [[Ingress]].

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: nginx-gateway
spec:
  controllerName: gateway.nginx.org/nginx-gateway-controller
```

## Gateway

Defines the entry point — ports, protocols, and TLS config. Owned by the infra team.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: prod-gateway
  namespace: infra
spec:
  gatewayClassName: nginx-gateway
  listeners:
  - name: http
    protocol: HTTP
    port: 80
  - name: https
    protocol: HTTPS
    port: 443
    tls:
      mode: Terminate
      certificateRefs:
      - name: prod-tls-secret
```

## HTTPRoute

Defines routing rules from a Gateway to backend [[Services]]. Owned by the app team.

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-route
  namespace: app
spec:
  parentRefs:
  - name: prod-gateway
    namespace: infra
  hostnames:
  - "myapp.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /api
    backendRefs:
    - name: api-service
      port: 80
  - matches:
    - path:
        type: PathPrefix
        value: /
    backendRefs:
    - name: web-service
      port: 80
```

## Traffic Splitting (Canary / Blue-Green)

Route a percentage of traffic to a new version — not possible natively with [[Ingress]].

```yaml
rules:
- backendRefs:
  - name: app-v1
    port: 80
    weight: 90   # 90% of traffic → stable version
  - name: app-v2
    port: 80
    weight: 10   # 10% of traffic → canary version
```

## Installing Gateway API CRDs

Gateway API is not built into Kubernetes — CRDs must be installed first.

```bash
# Install standard channel CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/latest/download/standard-install.yaml

# Verify CRDs are installed
kubectl get crd | grep gateway.networking.k8s.io
```

## Key Commands

```bash
# Check if Gateway API CRDs are installed
kubectl get crd | grep gateway.networking.k8s.io

# List GatewayClasses
kubectl get gatewayclass

# List all Gateways across namespaces
kubectl get gateway -A

# List all HTTPRoutes across namespaces
kubectl get httproute -A

# Describe Gateway — check listener status
kubectl describe gateway prod-gateway -n infra

# Describe HTTPRoute — check parentRef binding
kubectl describe httproute web-route -n app
```

## Common Issues / Troubleshooting

- **"resource not found" on `kubectl get gateway`** → Gateway API CRDs not installed; run the install command above
- **HTTPRoute not routing traffic** → check `parentRefs` — name and namespace must exactly match the Gateway
- **404 on all paths** → wrong `path.type`; use `PathPrefix` for prefix matching, `Exact` for exact
- **TLS not terminating** → `certificateRefs` must point to a valid TLS [[Secrets|Secret]] in the same namespace as the Gateway
- **Route not accepted by Gateway** → check `kubectl describe httproute` for `ResolvedRefs` and `Accepted` conditions

## Related Notes

- [[Ingress]] — The predecessor; still the primary exam topic for CKA
- [[Services]] — Backend targets for all HTTPRoute rules
- [[TLS in Kubernetes]] — TLS termination at the Gateway listener
- [[Network Policy]] — Controls east-west traffic; complements Gateway API at the edge
- [[Custom Resource Definition]] — Gateway API resources are CRDs under `gateway.networking.k8s.io`

## Key Mental Model

[[Ingress]] is a **single-owner tollbooth** — one team controls everything: the booth, the rules, and the road.

The **Gateway API** is a **split-ownership highway system** — the infra team builds and manages the on-ramps (Gateway), while each app team posts their own signs (HTTPRoute). Same destination, far less stepping on each other's toes.
