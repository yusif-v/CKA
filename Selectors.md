# Selectors
## **Overview**

**Selectors** are how Kubernetes **matches objects using labels**.
They define **relationships** between resources.

Labels say _what something is_.
Selectors say _which ones I care about_.

## Selector Types

Kubernetes supports **two selector styles**:
1. Equality-based selectors
2. Set-based selectors

Both operate only on **labels**.

## Equality-Based Selectors

Simple key-value matching.

### In kubectl

```bash
kubectl get pods -l app=web
```

```bash
kubectl get pods -l env!=prod
```

### In YAML

```yaml
selector:
  app: web
```

Used in:
- [[Service]]
- [[Replication Controller]]
- [[ReplicaSet Controller]]

## Set-Based Selectors

More expressive, supports multiple values.

### In kubectl

```bash
kubectl get pods -l 'env in (prod,staging)'
```

```bash
kubectl get pods -l 'tier notin (db)'
```

### In YAML

```yaml
selector:
  matchExpressions:
  - key: env
    operator: In
    values:
    - prod
    - staging
```

Operators:
- In
- NotIn
- Exists
- DoesNotExist

## Selectors in Core Resources
### Service Selector

```yaml
spec:
  selector:
    app: backend
```

Service routes traffic **only** to matching Pods.

If no match → no endpoints.

### ReplicaSet Selector

```yaml
spec:
  selector:
    matchLabels:
      app: web
```

ReplicaSet **adopts Pods** matching selector.

Mismatch = controller failure.

### Deployment Selector (Immutable)

```yaml
spec:
  selector:
    matchLabels:
      app: web
```

Once created:
- Selector **cannot be changed**
- Protects against accidental Pod adoption

## Node Selectors

Used for scheduling.

```yaml
nodeSelector:
  disktype: ssd
```

Matches **node labels**, not Pod labels.

## Label Selector vs Field Selector
### Label selector

```bash
kubectl get pods -l app=web
```

### Field selector

```bash
kubectl get pods --field-selector status.phase=Running
```

Difference:
- Labels → user-defined
- Fields → system-defined

## Empty & Missing Selectors

- Service with no selector → manual Endpoints
- Pod with no labels → unselectable
- Selector mismatch → silent failure

Always check:

```bash
kubectl get endpoints <service-name>
```

## Common Selector Mistakes

- Typo in label key
- Selector doesn’t match Pod template
- Changing labels without updating selector
- Confusing nodeSelector with pod labels

## Key Mental Model

Selectors are:
- Not queries
- Not filters applied later
- **Contracts**

Once a selector is defined, Kubernetes assumes:

> “These belong together — forever.”