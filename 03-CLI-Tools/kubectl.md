---
tags: [cka/architecture, cli]
aliases: [kubectl CLI, kube control]
---

# kubectl

> **Exam Domain**: All domains — kubectl is the primary exam tool
> **Related**: [[Kubeconfig]], [[Imperative Commands]], [[RBAC]], [[kube-apiserver]]

## Overview

**kubectl** is the command-line interface for interacting with a Kubernetes cluster. It communicates with [[kube-apiserver]] to create, update, delete, and retrieve cluster resources. It supports both **imperative commands** and **declarative manifests** — see [[Imperative Commands]] for exam shortcuts.

## Core Concepts

- Communicates via REST to [[kube-apiserver]]
- Uses [[Kubeconfig]] to authenticate and select cluster/user/namespace
- Supports multiple contexts for switching clusters
- Every command can be scoped to a namespace with `-n <namespace>`

## Essential Commands

### Basic CRUD

```bash
kubectl get <resource>                        # List resources
kubectl get <resource> -o wide                # Extra details
kubectl get <resource> -o yaml                # Full YAML output
kubectl describe <resource> <name>            # Detailed info + events
kubectl create -f <file.yaml>                 # Create from file
kubectl apply -f <file.yaml>                  # Create or update (declarative)
kubectl delete <resource> <name>              # Delete resource
kubectl delete -f <file.yaml>                 # Delete from file
```

### Pod Operations

```bash
kubectl logs <pod>                            # Container logs
kubectl logs <pod> -c <container>             # Specific container logs
kubectl logs <pod> --previous                 # Logs from crashed container
kubectl exec -it <pod> -- /bin/sh             # Shell into pod
kubectl exec -it <pod> -c <container> -- sh   # Specific container
kubectl port-forward <pod> 8080:80            # Forward local port to pod
kubectl cp <pod>:/path /local/path            # Copy files from pod
```

### Deployments & Scaling

```bash
kubectl scale deployment <name> --replicas=3
kubectl rollout status deployment <name>
kubectl rollout history deployment <name>
kubectl rollout undo deployment <name>
kubectl set image deployment <name> <container>=<image>
```

### Generating YAML (Exam Essential)

```bash
# Generate YAML without creating (dry run)
kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl create deployment web --image=nginx --dry-run=client -o yaml
kubectl create configmap my-cm --from-literal=key=val --dry-run=client -o yaml
```

### Context & Namespace

```bash
kubectl config get-contexts
kubectl config use-context <context>
kubectl config set-context --current --namespace=dev
```

### RBAC Testing

```bash
# Test permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'   # Check all permissions
```

## Output Formatting

```bash
-o yaml        # Full YAML
-o json        # JSON output
-o wide        # Extra columns
-o name        # Resource name only
-o jsonpath='{.metadata.name}'   # Extract specific field
```

## Common Flags

```bash
-n <namespace>           # Target namespace
--all-namespaces / -A    # All namespaces
-l <label-selector>      # Filter by label
--field-selector         # Filter by field
--dry-run=client         # Test without applying
-w                       # Watch for changes
--force                  # Force delete (use carefully)
--grace-period=0         # Immediate deletion
```

## Monitoring and Troubleshooting

```bash
kubectl get events                            # Cluster events
kubectl get events --sort-by=.lastTimestamp   # Sorted events
kubectl describe node <node>                  # Node health
kubectl get componentstatuses                 # Control plane health
kubectl top pods                              # Resource usage (needs metrics-server)
kubectl top nodes                             # Node resource usage
```

## Common Issues / Troubleshooting

- **"connection refused"** → kube-apiserver down or wrong server in kubeconfig
- **"forbidden"** → [[RBAC]] issue; check with `kubectl auth can-i`
- **"not found"** → wrong namespace or resource doesn't exist
- **kubectl slow** → apiserver under load or network issue

## Related Notes

- [[Kubeconfig]] — kubectl reads this for cluster connection info
- [[Imperative Commands]] — Quick creation patterns for the exam
- [[RBAC]] — Authorization layer kubectl goes through
- [[kube-apiserver]] — Everything kubectl does goes through it

## Key Mental Model

kubectl is a **thin REST client**. It translates your commands to HTTP requests, sends them to [[kube-apiserver]], and displays the response. Everything you can do with kubectl, you could do with `curl` — kubectl just makes it human-friendly.
