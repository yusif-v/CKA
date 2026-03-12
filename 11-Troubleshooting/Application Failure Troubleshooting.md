---
tags: [cka/troubleshooting, troubleshooting]
aliases: [App Failure, Application Debugging, App Troubleshooting]
---

# Application Failure Troubleshooting

> **Exam Domain**: Troubleshooting (30%)
> **Related**: [[Pod Troubleshooting]], [[Troubleshooting Guide]], [[Services]], [[Ingress]], [[Network Policy]], [[ConfigMap]], [[Secrets]], [[RBAC]]

## Overview

Application failure troubleshooting covers the full diagnostic chain from a user-facing symptom down to root cause. Unlike node or cluster failures, app failures are typically caused by misconfigured [[Services]], label selector mismatches, missing [[ConfigMap]] or [[Secrets]], crashing containers, or network policy blocks. The workflow drills top-down: can we reach the app? → are pods healthy? → is the service routing correctly? → is DNS working? → is an external [[Ingress]] broken?

> [!tip] Exam Tip
> On the CKA exam, application failure questions almost always have **one deliberate break**: a wrong label, a wrong port, a missing secret, or a bad image tag. Work through the chain systematically — don't jump to conclusions.

---

## The Application Failure Diagnostic Chain

```
1. Is the Pod running?             → kubectl get pods -n <ns>
2. Is the container healthy?       → kubectl describe pod / kubectl logs
3. Is the Service selecting Pods?  → kubectl get endpoints <svc>
4. Is the port mapping correct?    → kubectl describe svc <svc>
5. Is DNS resolving the Service?   → nslookup <svc> from inside a Pod
6. Is a NetworkPolicy blocking?    → kubectl get netpol -n <ns>
7. Is the Ingress routing right?   → kubectl describe ingress <ing>
```

---

## Step 1 — Check Pod Status

```bash
# Are pods running in the expected namespace?
kubectl get pods -n <namespace>

# If not in right namespace, search all
kubectl get pods -A | grep <app-name>
```

| Status | What it means |
|---|---|
| `Running` | Container started; check readiness and logs |
| `Pending` | Scheduling failed; check resources/taints |
| `CrashLoopBackOff` | App crashing; check logs with `--previous` |
| `ImagePullBackOff` | Bad image name or missing pull secret |
| `CreateContainerConfigError` | Missing [[ConfigMap]] or [[Secrets]] |
| `OOMKilled` | Memory limit too low |
| `Init:0/1` | Init container failing |

---

## Step 2 — Inspect Pod Events and Logs

```bash
# Full pod detail — Events section is key
kubectl describe pod <pod> -n <namespace>

# Current logs
kubectl logs <pod> -n <namespace>

# Logs from previous crash (CrashLoopBackOff)
kubectl logs <pod> -n <namespace> --previous

# Multi-container pod — specify container
kubectl logs <pod> -n <namespace> -c <container>

# Exec into running container to probe from inside
kubectl exec -it <pod> -n <namespace> -- /bin/sh
```

> [!tip] Exam Tip
> The **Events section** of `kubectl describe pod` gives you the reason in plain English 90% of the time. Always read it before going deeper.

---

## Step 3 — Verify the Service and Endpoints

The most common application failure cause on the CKA exam: **selector mismatch between Service and Pods**.

```bash
# Check the service exists in the right namespace
kubectl get svc -n <namespace>

# View service details — note selector, port, targetPort
kubectl describe svc <service> -n <namespace>

# Check endpoints — EMPTY = selector mismatch
kubectl get endpoints <service> -n <namespace>
```

### Diagnosing Empty Endpoints

```bash
# Step 1: Get the service's selector
kubectl describe svc <service> -n <namespace>
# Look for: Selector: app=backend

# Step 2: Check which pods match that selector
kubectl get pods -l app=backend -n <namespace>

# Step 3: Check the pod's actual labels
kubectl get pod <pod> -n <namespace> --show-labels

# Fix: either update the Service selector or add the label to the Pod/Deployment
kubectl label pod <pod> app=backend -n <namespace>
```

### Common Port Mismatches

```bash
# Service spec to inspect
kubectl describe svc <service> -n <namespace>
# port:       80   ← what clients call
# targetPort: 8080 ← what the container actually listens on

# Verify the container's actual port
kubectl describe pod <pod> -n <namespace>
# Look for: Ports: 8080/TCP
```

---

## Step 4 — Test Connectivity from Inside the Cluster

Spin up a debug pod to test networking and DNS from within the cluster:

```bash
# BusyBox debug pod (auto-deleted on exit)
kubectl run debug --image=busybox --rm -it -n <namespace> -- /bin/sh

# Test DNS resolution
nslookup <service-name>
nslookup <service-name>.<namespace>.svc.cluster.local

# Test HTTP
wget -qO- http://<service>:<port>
wget -qO- http://<service>.<namespace>:80

# Test TCP port reachability
nc -zv <service> <port>

# Curl image alternative
kubectl run debug --image=curlimages/curl --rm -it -- sh
curl -v http://<service>:<port>
```

> [!note] DNS Format
> From the **same namespace**: `http://my-service`
> From a **different namespace**: `http://my-service.other-ns`
> Full FQDN: `http://my-service.other-ns.svc.cluster.local`

---

## Step 5 — Check for NetworkPolicy Blocks

[[Network Policy]] silently drops traffic — no error message, just timeouts.

```bash
# List all network policies in namespace
kubectl get netpol -n <namespace>

# Inspect a specific policy — check podSelector and ingress/egress rules
kubectl describe netpol <policy> -n <namespace>
```

Signs of a NetworkPolicy block:
- Pod is `Running` and `Ready`
- Endpoints are populated
- Connection times out but doesn't refuse
- Adding `--timeout` to curl shows no response

Common fixes:
- Add ingress rule to allow traffic from the correct pod/namespace selector
- Allow egress to port 53 (UDP/TCP) if DNS is broken

---

## Step 6 — Check Ingress Routing

If the app is exposed externally via [[Ingress]]:

```bash
# List ingress resources
kubectl get ingress -n <namespace>

# Inspect rules — host, path, backend service, port
kubectl describe ingress <ingress> -n <namespace>

# Verify the backend service and port match an existing service
kubectl get svc -n <namespace>
```

Common Ingress problems:
- `host` field doesn't match the request hostname
- `pathType: Exact` vs `Prefix` mismatch
- Backend service name or port is wrong
- Ingress controller not installed or not running

```bash
# Check Ingress controller pods
kubectl get pods -n ingress-nginx
kubectl logs <ingress-controller-pod> -n ingress-nginx
```

---

## Step 7 — ConfigMap and Secret Issues

```bash
# Check if expected ConfigMap exists
kubectl get configmap -n <namespace>
kubectl describe configmap <name> -n <namespace>

# Check if expected Secret exists
kubectl get secret -n <namespace>

# Verify pod is referencing correct name
kubectl describe pod <pod> -n <namespace>
# Look for: Error: secret "db-secret" not found
#        or: Error: configmap "app-config" not found
```

> [!warning] Namespace Scope
> [[ConfigMap]] and [[Secrets]] are namespace-scoped. A pod in `dev` cannot reference a secret in `default`. The resource must exist in the **same namespace** as the Pod.

---

## Step 8 — Environment Variable and Command Issues

```bash
# Check what env vars the container actually has
kubectl exec <pod> -n <namespace> -- env

# Check what command/args the container is running
kubectl describe pod <pod> -n <namespace>
# Look for: Command/Args sections

# Check resource limits (OOMKilled / throttling)
kubectl describe pod <pod> -n <namespace>
# Look for: Limits / Requests
```

---

## Full Quick-Reference Checklist

```
□ kubectl get pods -n <ns>            → pod status
□ kubectl describe pod <pod>          → events, config issues
□ kubectl logs <pod> [--previous]     → app errors
□ kubectl get endpoints <svc>         → empty = selector mismatch
□ kubectl describe svc <svc>          → port/targetPort/selector
□ kubectl get netpol -n <ns>          → network policy blocks
□ kubectl describe ingress            → routing rules
□ kubectl get configmap/secret        → missing resources
□ debug pod: nslookup / wget / nc     → DNS + connectivity
```

---

## Common Scenarios and Fixes

| Symptom | Likely Cause | Fix |
|---|---|---|
| Pod `CrashLoopBackOff` | App crashing on start | `logs --previous`; check env/config |
| Pod `Running` but no traffic | Service selector mismatch | Fix labels or selector |
| Empty endpoints | Label mismatch | `kubectl label pod` or fix selector |
| `ImagePullBackOff` | Wrong image or no pull secret | Fix image tag; add `imagePullSecrets` |
| `CreateContainerConfigError` | Missing ConfigMap/Secret | Create the missing resource |
| DNS not resolving | CoreDNS down or wrong namespace | `kubectl get pods -n kube-system` |
| Connection times out silently | NetworkPolicy blocking | `kubectl get netpol` + check rules |
| Ingress returns 404 | Path or host mismatch | `kubectl describe ingress` |
| App `OOMKilled` | Memory limit too low | Increase `limits.memory` |
| RBAC `403 Forbidden` | Missing Role/RoleBinding | `kubectl auth can-i`; fix [[RBAC]] |

---

## Related Notes

- [[Pod Troubleshooting]] — Deep dive into pod status diagnosis
- [[Troubleshooting Guide]] — Master workflow for all cluster issues
- [[Services]] — Service types, selectors, and port mapping
- [[Network Policy]] — How to read and fix blocking policies
- [[Ingress]] — HTTP routing layer on top of Services
- [[ConfigMap]] — Application configuration mounting
- [[Secrets]] — Sensitive config; namespace-scoped
- [[RBAC]] — Permission errors in app-to-API access
- [[CoreDNS]] — DNS resolution failures inside the cluster

---

## Key Mental Model

Application failure troubleshooting is a **path-tracing exercise**: follow the request from where the user hits it (Ingress → Service → Endpoints → Pod → Container) and find where the path breaks. Every layer has exactly one command that reveals the truth. The break is almost always at the **Service-to-Pod boundary** (selector mismatch) or inside the **container itself** (bad config, missing secret, app bug). Start at the edges, work inward.
