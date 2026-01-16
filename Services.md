## Overview

A **Service** provides a **stable network identity** for a set of Pods.

Pods are ephemeral; Services are not.

A Service solves three problems:
- Pod IPs change
- Load balancing across replicas
- Service discovery inside the cluster

## Core Concepts

- Uses **labels & selectors** to find Pods
- Gets a **virtual IP (ClusterIP)**
- kube-proxy programs traffic routing rules
- Traffic is distributed across matching Pods

```bash
Client → Service → Pod
```

## Service Types
### ClusterIP (default)

- Internal-only access
- Used for app-to-app communication

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
  - port: 80
    targetPort: 8080
```

### NodePort

- Exposes Service on each Node’s IP    
- Port range: **30000–32767**

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
    nodePort: 30080
```

Access:

```bash
http://<NodeIP>:30080
```

### LoadBalancer

- Cloud-provider integration
- Provisions external load balancer

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

- Maps Service to an external DNS name
- No selectors, no Pods

```yaml
apiVersion: v1
kind: Service
metadata:
  name: external-db
spec:
  type: ExternalName
  externalName: db.example.com
```

## Ports Explained

- port → Service port
- targetPort → Pod container port
- nodePort → Node-level port (NodePort only)

## DNS & Service Discovery

Kubernetes DNS automatically creates records:

```bash
<service-name>.<namespace>.svc.cluster.local
```

Example:

```bash
backend.dev.svc.cluster.local
```

Inside same namespace:

```bash
http://backend
```

## Headless Services

No ClusterIP; returns Pod IPs directly.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  clusterIP: None
  selector:
    app: db
  ports:
  - port: 3306
```

Used for:
- StatefulSets
- Direct Pod discovery

## kube-proxy Role

[[kube-proxy]]:
- Watches Services & Endpoints
- Programs iptables or IPVS rules
- Handles load balancing

## Inspecting Services
### List Services

```bash
kubectl get svc
```

### Describe Service

```bash
kubectl describe svc backend
```

### View Endpoints

```bash
kubectl get endpoints
```

If endpoints are empty → label mismatch.

## Common Failure Patterns

- Selector does not match Pod labels
- Pod not Ready
- Wrong targetPort
- NetworkPolicy blocking traffic

## Key Mental Model

A Service is:
- Not a process
- Not a load balancer daemon
- A **virtual IP + rules**

Pods come and go.
Services stay put.