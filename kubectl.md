#cli 
## Overview

kubectl is the **command-line interface** for interacting with a Kubernetes cluster. It communicates with the **kube-apiserver** to create, update, delete, and retrieve cluster resources.

It supports **imperative commands** and **declarative manifests**, making it the primary tool for cluster management and troubleshooting.

## Core Concepts

- **Client → API Server** communication via REST
- Uses **kubeconfig** to authenticate and select clusters/users    
- Supports multiple **contexts** for switching clusters and namespaces
- Operates declaratively (YAML) or imperatively (CLI flags)

## Common Commands
### Basic Operations

```bash
kubectl get <resource>              # List resources (pods, nodes, services)
kubectl describe <resource> <name>  # Detailed information about a resource
kubectl create -f <file>            # Create resources from YAML or flags
kubectl apply -f <file>             # Apply a manifest declaratively
kubectl delete <resource> <name>    # Remove resources
```

### Pod Operations

```bash
kubectl logs <pod>                          # View container logs
kubectl exec -it <pod> -- <command>         # Execute commands inside a container
kubectl port-forward <pod> <local>:<remote> # Forward local port to Pod
```

### Resource Management

```bash
kubectl scale deployment/<name> --replicas=<n>   # Adjust replicas
kubectl rollout status deployment/<name>         # Check rollout status
kubectl set image deployment/<name> <container>=<image>  # Update container image
kubectl top pod <pod>                             # Resource usage (requires Metrics Server)
```

### Configuration & Context

```bash
kubectl config get-contexts        # List contexts
kubectl config use-context <name>  # Switch context
kubectl config view                # View kubeconfig
```

## Flags and Options

```bash
-n <namespace>          # Specify namespace
-f <file>               # Apply manifest file
--kubeconfig <path>     # Specify kubeconfig path
-o <format>             # Output formatting (yaml, json, wide, name)
--dry-run=client|server # Test changes without applying
```

## Interaction with Cluster

- Talks only to **kube-apiserver**
- Requests authenticated and authorized via **RBAC**
- Changes cluster state indirectly by updating resources
- Can watch resources:

```bash
kubectl get pods -w  # Watch resources in real-time
```

## Monitoring and Troubleshooting

```bash
kubectl get events                       # List cluster events
kubectl describe node <node>             # Node health and conditions
kubectl describe pod <pod>               # Pod state, events, probes
kubectl get componentstatuses            # Control plane health check
kubectl get pod <pod> -o yaml            # Raw resource inspection
```

## Advanced Usage

```bash
kubectl diff -f <file>                       # Preview changes
kubectl apply --prune -f <dir>               # Remove resources not in manifest
kubectl auth can-i <verb> <resource>         # Test RBAC permissions
kubectl wait --for=condition=Ready pod/<pod> # Wait for resource readiness
```
