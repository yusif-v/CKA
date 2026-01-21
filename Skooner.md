# Skooner
## **Overview**

**Skooner** is a **web-based Kubernetes dashboard** used to visualize and manage cluster resources.

It provides a **real-time UI** for inspecting workloads, configurations, and cluster state without relying only on kubectl.

Skooner is **read-heavy by design** and commonly used for **visibility and learning**, not production-grade cluster administration.

## What Skooner Shows

- Nodes, Pods, Deployments, ReplicaSets
- Namespaces
- Services
- ConfigMaps & Secrets (metadata only)
- Resource usage (CPU / memory)
- Pod logs and container status

## Architecture (High Level)

- Runs as a **Pod inside the cluster**
- Communicates with the Kubernetes API Server
- Uses **ServiceAccount + RBAC** for access
- Exposes a web UI (usually via NodePort or port-forward)

🔗 Related:

- [[kube-apiserver]]
- [[RBAC]]
- [[ServiceAccount]]

## Installation (Typical)

```
kubectl apply -f https://raw.githubusercontent.com/skooner-k8s/skooner/master/kubernetes-skooner.yaml
```

Check Pod:

```
kubectl get pods -n kube-system
```

## Accessing the UI

Using port-forward:

```
kubectl port-forward -n kube-system service/skooner 8080:80
```

Then open:

```
http://localhost:8080
```

## Authentication & Security

- Uses Kubernetes authentication (ServiceAccount)
- Permissions controlled via RBAC
- **Not recommended to expose publicly**
- Often deployed with **read-only access**


🔗 Related:

- [[RBAC]]
- [[Security Context]]
- [[Authentication]]

## Use Cases

- Visualizing cluster state
- Learning Kubernetes object relationships
- Debugging Pod lifecycle issues
- Monitoring rollout behavior
- Teaching Kubernetes concepts

## Limitations

- Not a full replacement for kubectl
- Limited write operations
- Less maintained than official Kubernetes Dashboard
- Should not be used as a primary admin tool in production

## Skooner vs Kubernetes Dashboard

|**Feature**|**Skooner**|**Kubernetes Dashboard**|
|---|---|---|
|UI Simplicity|Very clean|Feature-rich|
|Write Operations|Limited|Extensive|
|Learning Tool|Excellent|Moderate|
|Production Use|Not recommended|With care|

## Key Mental Model

Skooner is a **window, not a steering wheel**.

It lets you **see** what’s happening inside the cluster clearly,
but real control still lives in:
- kubectl
- YAML manifests
- CI/CD pipelines

Think of Skooner as **observability for humans**, not automation for machines.