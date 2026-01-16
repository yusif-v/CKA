# Imperative Commands
## Overview

**Imperative commands** tell Kubernetes **what to do right now**.
They contrast with **declarative YAML**, which describes desired state.

Mental split:

```
Imperative → “Do this now”
Declarative → “This is how it should look”
```

## Creating Resources Imperatively

### Pod

```bash
kubectl run nginx --image=nginx
```

With labels:

```bash
kubectl run nginx --image=nginx --labels="app=web"
```

Dry run (generate YAML):

```bash
kubectl run nginx --image=nginx --dry-run=client -o yaml
```

### Deployment

```bash
kubectl create deployment web --image=nginx
```

Scale:

```bash
kubectl scale deployment web --replicas=3
```

Expose:

```bash
kubectl expose deployment web --port=80 --target-port=80
```

### Service
#### ClusterIP

```
kubectl expose pod nginx --port=80 --target-port=80
```

#### NodePort

```bash
kubectl expose deployment web \
  --type=NodePort \
  --port=80 \
  --target-port=80
```

### Namespace

```bash
kubectl create namespace dev
```

## Updating Resources
### Change image

```bash
kubectl set image deployment/web nginx=nginx:1.25
```

### Add label

```bash
kubectl label pod nginx env=prod
```

### Annotate

```bash
kubectl annotate pod nginx owner=team-a
```

## Editing & Patching
### Edit live resource

```bash
kubectl edit deployment web
```

### Patch (JSON merge patch)

```bash
kubectl patch deployment web \
  -p '{"spec":{"replicas":5}}'
```

## Deleting Resources

```bash
kubectl delete pod nginx
kubectl delete deployment web
kubectl delete svc web
kubectl delete namespace dev
```

Delete by label:

```bash
kubectl delete pods -l app=web
```

## Debugging Imperatively
### Get wide output

```bash
kubectl get pods -o wide
```

### Describe

```bash
kubectl describe pod nginx
```

### Logs

```bash
kubectl logs nginx
```

### Exec into container

```bash
kubectl exec -it nginx -- /bin/sh
```

## Context & Namespace Shortcuts

```bash
kubectl config use-context my-cluster
kubectl config set-context --current --namespace=dev
```

## Key Mental Model

Imperative commands are:
- Fast
- Temporary    
- Human-driven

YAML is:
- Repeatable
- Auditable
- Machine-friendly
