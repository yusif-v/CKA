# CoreDNS
## Overview

**CoreDNS** is the DNS server used inside a Kubernetes cluster to provide **service discovery**.

It translates Service names into IP addresses so Pods can communicate using stable names instead of changing IPs.

Because Pods are ephemeral and can be recreated at any time, their IP addresses are not reliable. CoreDNS provides a consistent naming layer so applications can always find each other.

CoreDNS = _Cluster DNS and Service Discovery Mechanism_

## Why CoreDNS Exists

In Kubernetes:
1. Pods are constantly created and destroyed.
2. Each Pod gets a new IP address.
3. Hardcoding IPs would break communication.

CoreDNS allows workloads to communicate using **names instead of IP addresses**, making the system resilient and dynamic.

## How CoreDNS Works

Workflow:

```bash
Pod sends DNS query → CoreDNS receives request →
Looks up Service in API Server → Returns ClusterIP →
Traffic routed to matching Pod
```

CoreDNS continuously watches the Kubernetes API and automatically updates DNS records when:
- Services are created or deleted
- Pods change
- Namespaces change

No manual DNS updates are required.

## DNS Naming Convention

Kubernetes automatically generates DNS names using this structure:

```bash
<service-name>.<namespace>.svc.cluster.local
```

Example:

|**Service**|**Namespace**|**DNS Name**|
|---|---|---|
|web|default|web.default.svc.cluster.local|
|db|prod|db.prod.svc.cluster.local|

Inside the same namespace, short names can be used:

```bash
curl http://web
```

## CoreDNS Deployment

CoreDNS runs as a Deployment in the kube-system namespace.

Check CoreDNS Pods:

```bash
kubectl get pods -n kube-system | grep coredns
```

## CoreDNS Configuration (Corefile)

CoreDNS behavior is controlled by a configuration file called the **Corefile**, stored inside a ConfigMap.

View it:

```bash
kubectl -n kube-system get configmap coredns -o yaml
```

Example configuration:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system

data:
  Corefile: |
    .:53 {
        errors
        health
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
        }
        forward . /etc/resolv.conf
        cache 30
        reload
        loadbalance
    }
```

## Important CoreDNS Plugins

|**Plugin**|**Purpose**|
|---|---|
|kubernetes|Enables Kubernetes service discovery|
|forward|Forwards external DNS queries|
|cache|Caches DNS responses for performance|
|loadbalance|Balances DNS responses|
|health|Provides health checks|
|reload|Reloads config without restart|

CoreDNS is plugin-based, allowing flexible DNS behavior.

## Service Discovery Types
### ClusterIP Service

Returns the virtual IP of the Service.

```bash
my-service.default.svc.cluster.local → ClusterIP
```

Traffic is then load-balanced to backend Pods.

### Headless Service

Returns individual Pod IPs instead of a single ClusterIP.

Used by StatefulSets and applications needing direct Pod access.

```bash
pod-0.db.default.svc.cluster.local → Pod IP
```

## Debugging DNS Issues

Run a temporary test Pod:

```bash
kubectl run dns-test --image=busybox:1.28 --rm -it --restart=Never -- sh
```

Inside the Pod:

```bash
nslookup kubernetes.default
nslookup my-service
cat /etc/resolv.conf
```

## Useful Commands

```bash
kubectl get pods -n kube-system
kubectl logs -n kube-system deployment/coredns

kubectl -n kube-system get configmap coredns
kubectl describe svc kube-dns -n kube-system
```

## Common Issues

|**Problem**|**Cause**|
|---|---|
|Services not resolving|CoreDNS Pod down|
|Slow DNS responses|Cache misconfiguration|
|Wrong resolution|Namespace mismatch|
|External DNS failing|Forward plugin issue|

## Important Behavior

CoreDNS does not store static DNS records.

It dynamically builds DNS entries by watching the Kubernetes API.
When Services or Pods change, DNS records update automatically.

This makes Kubernetes networking adaptive and self-healing.

## Summary

CoreDNS provides internal DNS-based service discovery in Kubernetes by automatically mapping Service names to their reachable IP addresses, allowing applications to communicate reliably despite constantly changing Pod lifecycles.