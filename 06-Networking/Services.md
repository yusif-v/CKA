---
tags: [cka/networking, networking]
aliases: [Service, ClusterIP, NodePort, LoadBalancer]
---

# Services

> **Exam Domain**: Services & Networking (20%)
> **Related**: [[kube-proxy]], [[Pods]], [[Ingress]], [[Network Policy]], [[Labels]], [[Namespaces]]

## Overview

A **Service** provides a **stable network identity** for a set of [[Pods]]. Pods are ephemeral — their IPs change. Services are not. A Service solves three problems: Pod IPs change, load balancing is needed across replicas, and stable service discovery inside the cluster is required.

## Service Types

### ClusterIP (default)

Internal-only virtual IP. Use for service-to-service communication:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 80          # Service port
    targetPort: 8080  # Pod container port
```

### NodePort

Exposes Service on each Node's IP. Port range: **30000–32767**:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080   # Optional; auto-assigned if omitted
```

Access: `http://<NodeIP>:30080`

### LoadBalancer

Cloud-provider integration — provisions external load balancer:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-lb
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

### ExternalName

Maps Service to external DNS name (no Pods):

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

### Headless Service

No ClusterIP — returns Pod IPs directly (used by StatefulSets):

```yaml
spec:
  clusterIP: None
  selector:
    app: db
```

## How Services Work

```
Client → ClusterIP (virtual) → kube-proxy (iptables/IPVS rules) → Pod IP
```

[[kube-proxy]] on each Node programs routing rules that transparently forward traffic from the Service's virtual IP to actual Pod IPs.

## DNS and Service Discovery

Kubernetes DNS creates records automatically:

```
<service-name>.<namespace>.svc.cluster.local
```

From the **same namespace**: `http://backend`
From **another namespace**: `http://backend.dev`
Full FQDN: `http://backend.dev.svc.cluster.local`

## Key Commands

```bash
# List services
kubectl get svc
kubectl get svc -A   # All namespaces

# Describe service
kubectl describe svc backend

# Check endpoints (pods the service routes to)
kubectl get endpoints backend

# Create service imperatively
kubectl expose deployment web --port=80 --target-port=8080 --type=ClusterIP

# Expose as NodePort
kubectl expose deployment web --port=80 --type=NodePort

# Test service connectivity
kubectl run tmp --image=busybox --rm -it -- wget -qO- http://backend
```

## Common Issues / Troubleshooting

- **No endpoints** → selector doesn't match Pod labels; `kubectl get endpoints <svc>` shows empty
- **Service unreachable** → Pod not Ready (readiness probe failing)
- **Wrong targetPort** → traffic hitting wrong port on Pod
- **[[Network Policy]] blocking traffic** → check if NetworkPolicy allows the traffic path
- **DNS not resolving** → CoreDNS not running; `kubectl get pods -n kube-system | grep coredns`

## Related Notes

- [[kube-proxy]] — Implements Service routing rules on each Node
- [[Ingress]] — HTTP/HTTPS routing layer on top of Services
- [[Network Policy]] — Controls traffic to/from Services
- [[Labels]] — Service selector uses pod labels
- [[Namespaces]] — Services are namespace-scoped; DNS includes namespace

## Key Mental Model

A Service is not a process or daemon — it is a **virtual IP + routing rules**. Pods come and go; Services stay put. [[kube-proxy]] ensures that traffic aimed at the Service's virtual IP always finds its way to a healthy, running Pod.
