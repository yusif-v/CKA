---
tags: [cka/architecture, cli]
aliases: [imperative, kubectl shortcuts, exam commands]
---

# Imperative Commands

> **Exam Domain**: All — imperative commands save critical time on the CKA exam
> **Related**: [[kubectl]], [[Pods]], [[Deployments]], [[Services]], [[Namespaces]]

## Overview

**Imperative commands** tell Kubernetes **what to do right now**, as opposed to declarative YAML which describes desired state. On the CKA exam, imperative commands are essential for **speed** — generating YAML scaffolds with `--dry-run=client -o yaml` is the most important technique.

> [!tip] Exam Tip
> Use `--dry-run=client -o yaml > file.yaml` to generate a YAML template, then edit it. Much faster than writing YAML from scratch.

## Creating Resources

### Pods

```bash
# Create pod
kubectl run nginx --image=nginx

# Create with labels
kubectl run nginx --image=nginx --labels="app=web,env=prod"

# Create with port exposed
kubectl run nginx --image=nginx --port=80

# Generate YAML only (don't create)
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Create and override command
kubectl run busybox --image=busybox -- sleep 3600
```

### Deployments

```bash
# Create deployment
kubectl create deployment web --image=nginx

# With replicas
kubectl create deployment web --image=nginx --replicas=3

# Generate YAML
kubectl create deployment web --image=nginx --dry-run=client -o yaml > deploy.yaml

# Scale
kubectl scale deployment web --replicas=5
```

### Services

```bash
# Expose a pod
kubectl expose pod nginx --port=80 --target-port=80

# Expose deployment as ClusterIP
kubectl expose deployment web --port=80 --target-port=80

# Expose as NodePort
kubectl expose deployment web --type=NodePort --port=80

# Expose as LoadBalancer
kubectl expose deployment web --type=LoadBalancer --port=80
```

### ConfigMaps and Secrets

```bash
# ConfigMap from literal
kubectl create configmap my-cm --from-literal=key1=val1 --from-literal=key2=val2

# ConfigMap from file
kubectl create configmap my-cm --from-file=config.properties

# Secret from literal
kubectl create secret generic my-secret \
  --from-literal=user=admin \
  --from-literal=pass=secret123

# TLS secret
kubectl create secret tls my-tls --cert=cert.crt --key=key.key

# Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

### Namespaces, RBAC, and Others

```bash
# Namespace
kubectl create namespace dev

# ServiceAccount
kubectl create serviceaccount my-sa -n dev

# Role
kubectl create role pod-reader \
  --verb=get,list,watch \
  --resource=pods \
  -n dev

# RoleBinding
kubectl create rolebinding pod-reader-binding \
  --role=pod-reader \
  --user=alice \
  -n dev

# ClusterRole
kubectl create clusterrole cluster-reader \
  --verb=get,list,watch \
  --resource=pods,nodes

# ClusterRoleBinding
kubectl create clusterrolebinding cluster-reader-binding \
  --clusterrole=cluster-reader \
  --user=alice
```

## Updating Resources

```bash
# Change image
kubectl set image deployment/web nginx=nginx:1.26

# Add/overwrite label
kubectl label pod nginx env=prod --overwrite

# Remove label
kubectl label pod nginx env-

# Annotate
kubectl annotate pod nginx owner=team-a

# Edit live resource (opens editor)
kubectl edit deployment web

# Patch inline
kubectl patch deployment web -p '{"spec":{"replicas":5}}'
```

## Deleting Resources

```bash
kubectl delete pod nginx
kubectl delete deployment web
kubectl delete svc web
kubectl delete namespace dev

# Delete by label
kubectl delete pods -l app=web

# Force delete (immediate)
kubectl delete pod nginx --force --grace-period=0

# Delete from file
kubectl delete -f resource.yaml
```

## Debugging

```bash
kubectl get pods -o wide
kubectl describe pod nginx
kubectl logs nginx
kubectl logs nginx --previous
kubectl exec -it nginx -- /bin/sh
```

## Key Mental Model

Imperative commands are **fast, temporary, human-driven**. YAML is **repeatable, auditable, machine-friendly**. On the exam: use imperative to generate, edit the YAML if needed, then apply.
