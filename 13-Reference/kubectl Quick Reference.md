---
tags: [cka, reference, cli]
aliases: [kubectl Reference, kubectl Commands, kubectl Cheatsheet]
---

# kubectl Quick Reference

> **Exam Domain**: All — kubectl is used in every CKA domain
> **Related**: [[kubectl]], [[Imperative Commands]], [[Exam Cheatsheet]], [[Kubeconfig]]

## Context & Namespace

```bash
# View and switch contexts
kubectl config get-contexts
kubectl config current-context
kubectl config use-context <context>
kubectl config set-context --current --namespace=<ns>

# View config
kubectl config view
kubectl config view --raw   # Show certs too
```

## Getting Resources

```bash
# Basic get
kubectl get <resource>
kubectl get <resource> -n <namespace>
kubectl get <resource> -A             # All namespaces
kubectl get <resource> --show-labels
kubectl get <resource> -o wide        # More columns
kubectl get <resource> -o yaml        # Full YAML
kubectl get <resource> -o json        # JSON output
kubectl get <resource> -o name        # Names only
kubectl get <resource> -w             # Watch for changes

# Filter by label
kubectl get pods -l app=web
kubectl get pods -l 'env in (prod,staging)'

# Filter by field
kubectl get pods --field-selector status.phase=Running
kubectl get pods --field-selector spec.nodeName=worker-1

# JSONPath extraction
kubectl get pod <pod> -o jsonpath='{.metadata.name}'
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].image}'
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'
```

## Describing Resources

```bash
kubectl describe pod <pod>
kubectl describe node <node>
kubectl describe svc <service>
kubectl describe deployment <deploy>
kubectl describe pvc <pvc>
kubectl describe secret <secret>
kubectl describe configmap <cm>
```

## Creating Resources

```bash
# From file
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/
kubectl create -f <file.yaml>

# Imperative
kubectl run <name> --image=<image>
kubectl create deployment <name> --image=<image>
kubectl create namespace <name>
kubectl create configmap <name> --from-literal=key=val
kubectl create secret generic <name> --from-literal=key=val

# Dry run (generate YAML)
kubectl run nginx --image=nginx --dry-run=client -o yaml
kubectl create deployment web --image=nginx --dry-run=client -o yaml
```

## Updating Resources

```bash
# Edit live resource
kubectl edit <resource> <name>

# Set image
kubectl set image deployment/<deploy> <container>=<image>

# Scale
kubectl scale deployment <deploy> --replicas=5

# Patch (inline)
kubectl patch deployment <deploy> -p '{"spec":{"replicas":3}}'

# Add label
kubectl label pod <pod> env=prod
kubectl label pod <pod> env=prod --overwrite

# Remove label
kubectl label pod <pod> env-

# Annotate
kubectl annotate pod <pod> description="my pod"

# Rollout commands
kubectl rollout status deployment/<deploy>
kubectl rollout history deployment/<deploy>
kubectl rollout undo deployment/<deploy>
kubectl rollout undo deployment/<deploy> --to-revision=2
kubectl rollout pause deployment/<deploy>
kubectl rollout resume deployment/<deploy>
kubectl rollout restart deployment/<deploy>
```

## Deleting Resources

```bash
kubectl delete pod <pod>
kubectl delete deployment <deploy>
kubectl delete -f <file.yaml>
kubectl delete pod <pod> --force --grace-period=0
kubectl delete pods -l app=web    # By label
kubectl delete namespace <ns>     # Deletes everything inside
```

## Pod Logs

```bash
kubectl logs <pod>
kubectl logs <pod> -c <container>    # Specific container
kubectl logs <pod> --previous        # Previous (crashed) container
kubectl logs <pod> -f                # Stream/follow
kubectl logs <pod> --tail=50         # Last N lines
kubectl logs <pod> --since=1h        # Since time
kubectl logs -l app=web              # By label selector
```

## Exec and Port-Forward

```bash
# Shell into pod
kubectl exec -it <pod> -- /bin/sh
kubectl exec -it <pod> -c <container> -- /bin/bash

# Single command
kubectl exec <pod> -- env
kubectl exec <pod> -- cat /etc/config/key

# Port forward
kubectl port-forward pod/<pod> 8080:80
kubectl port-forward svc/<service> 8080:80
kubectl port-forward deployment/<deploy> 8080:80
```

## Copying Files

```bash
kubectl cp <pod>:/path/to/file /local/path
kubectl cp /local/file <pod>:/remote/path
```

## Resource Usage (Metrics)

```bash
kubectl top nodes
kubectl top pods
kubectl top pods --containers
kubectl top pods -l app=web
```

## Events

```bash
# All events
kubectl get events
kubectl get events -n <namespace>
kubectl get events --sort-by=.lastTimestamp

# Events for specific resource
kubectl get events --field-selector involvedObject.name=<pod>
kubectl get events --field-selector involvedObject.kind=Node
```

## RBAC & Auth

```bash
# Test permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'

# Create role/binding
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding alice --role=pod-reader --user=alice -n dev
kubectl create clusterrole reader --verb=get,list --resource=pods
kubectl create clusterrolebinding alice-reader --clusterrole=reader --user=alice

# View roles
kubectl get roles,rolebindings -n dev
kubectl get clusterroles,clusterrolebindings
```

## Taints & Labels

```bash
# Labels
kubectl label node worker-1 disktype=ssd
kubectl label node worker-1 disktype-   # Remove
kubectl get nodes --show-labels

# Taints
kubectl taint nodes node1 key=val:NoSchedule
kubectl taint nodes node1 key=val:NoSchedule-   # Remove
kubectl describe node node1 | grep Taint

# Cordon/Drain
kubectl cordon node1
kubectl drain node1 --ignore-daemonsets --delete-emptydir-data
kubectl uncordon node1
```

## Cluster Info

```bash
kubectl cluster-info
kubectl get componentstatuses
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl version
kubectl api-resources
kubectl api-versions
kubectl explain <resource>
kubectl explain <resource>.<field>
```

## Kubeconfig

```bash
# View
kubectl config view
kubectl config get-contexts
kubectl config current-context

# Switch
kubectl config use-context <context>

# Set namespace
kubectl config set-context --current --namespace=<ns>

# Add context
kubectl config set-context <name> --cluster=<c> --user=<u> --namespace=<ns>
```

## Output Formats Reference

| Format | Usage |
|---|---|
| `-o yaml` | Full resource YAML |
| `-o json` | Full resource JSON |
| `-o wide` | Additional columns |
| `-o name` | Resource names only |
| `-o jsonpath='<expr>'` | Extract specific fields |
| `-o custom-columns=COL:.path` | Custom column output |

## Related Notes

- [[kubectl]] — Conceptual overview and core patterns
- [[Imperative Commands]] — All creation shortcuts
- [[Exam Cheatsheet]] — Exam-focused quick reference
- [[Kubeconfig]] — Context and authentication management
