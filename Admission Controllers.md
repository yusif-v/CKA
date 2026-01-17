# Admission Controllers
## Overview

**Admission Controllers** are components in Kubernetes that **intercept requests to the API server after authentication and authorization but before persistence**.

They act as **policy gates** that can:
- Validate requests
- Modify requests
- Reject requests

They are part of the request lifecycle handled by [[kube-apiserver]].

## Request Flow Context

A typical API request flows like this:
1. Authentication
2. Authorization
3. **Admission Controllers**
4. Object is persisted in etcd

Admission Controllers are the **last checkpoint** before data is stored.

## Types of Admission Controllers
### Mutating Admission Controllers

- Can **modify** incoming objects
- Executed **first**
- Example:
    - Inject sidecars
    - Add default labels
    - Add resource limits

Example built-in plugin:
- MutatingAdmissionWebhook

### Validating Admission Controllers

- Can **accept or reject**
- Cannot modify objects
- Executed **after mutating controllers**

Example built-in plugin:
- ValidatingAdmissionWebhook

## Built-in Admission Controllers

Some common built-in controllers include:
- NamespaceLifecycle
- ResourceQuota
- LimitRanger
- ServiceAccount
- PodSecurity (replaces PSP)
- DefaultStorageClass

They are enabled via API server configuration.

## Webhook Admission Controllers

Kubernetes allows **custom admission logic** via webhooks.

Webhook flow:
1. API server sends object to external service
2. Service responds with allow/deny or mutation
3. API server proceeds accordingly

Defined using:
- MutatingWebhookConfiguration
- ValidatingWebhookConfiguration

## Example Use Cases

- Enforce required labels
- Block privileged containers
- Inject logging or monitoring sidecars
- Enforce resource requests and limits
- Validate naming conventions

## Admission Controller Configuration

Enabled using API server flags:

```bash
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount
```

Or configured via API server config file.

## Observability and Debugging

Check enabled plugins:

```bash
kubectl exec -n kube-system kube-apiserver-<node> -- kube-apiserver -h
```

Inspect webhook configurations:

```bash
kubectl get mutatingwebhookconfiguration
kubectl get validatingwebhookconfiguration
```

## Failure Modes

- If a validating webhook fails, requests may be rejected
- If a mutating webhook fails, behavior depends on failurePolicy
- Misconfigured webhooks can block cluster operations

## Security Implications

Admission Controllers are **powerful**:
- They can block or modify all cluster activity
- Must be highly available and well-tested
- Poorly written webhooks can destabilize clusters

## Key Mental Model

Admission Controllers are **customs officers** at the Kubernetes border.

Authentication checks your passport.
Authorization checks your visa.
Admission Controllers inspect your luggage — and decide whether you enter, and in what shape.