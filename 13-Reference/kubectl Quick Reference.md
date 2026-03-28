---
tags: [cka, reference, cli]
aliases: [kubectl Reference, kubectl Commands, kubectl Cheatsheet]
---

# kubectl Quick Reference

> **Exam Domain**: All — kubectl is used in every CKA domain
> **Related**: [[kubectl]], [[Imperative Commands]], [[Exam Cheatsheet]], [[Kubeconfig]]

---

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

# Set alias (do this first on every exam task)
alias k=kubectl
```

---

## Getting Resources

```bash
# Basic get
kubectl get <resource>
kubectl get <resource> -n <namespace>
kubectl get <resource> -A                  # All namespaces
kubectl get <resource> --show-labels
kubectl get <resource> -o wide             # More columns
kubectl get <resource> -o yaml             # Full YAML
kubectl get <resource> -o json             # JSON output
kubectl get <resource> -o name             # Names only
kubectl get <resource> -w                  # Watch for changes

# Filter by label
kubectl get pods -l app=web
kubectl get pods -l 'env in (prod,staging)'
kubectl get pods -l 'tier notin (db)'
kubectl get pods -l '!disktype'            # Label does not exist

# Filter by field
kubectl get pods --field-selector status.phase=Running
kubectl get pods --field-selector spec.nodeName=worker-1
kubectl get pods --field-selector status.phase=Pending -A

# JSONPath extraction
kubectl get pod <pod> -o jsonpath='{.metadata.name}'
kubectl get pod <pod> -o jsonpath='{.status.podIP}'
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].image}'
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'
kubectl get pod <pod> -o jsonpath='{.spec.serviceAccountName}'
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'
kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}'

# Custom columns
kubectl get pods -o custom-columns=NAME:.metadata.name,NODE:.spec.nodeName,STATUS:.status.phase
kubectl get pv -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.capacity.storage,RECLAIM:.spec.persistentVolumeReclaimPolicy
```

---

## Describing Resources

```bash
kubectl describe pod <pod>
kubectl describe node <node>
kubectl describe svc <service>
kubectl describe deployment <deploy>
kubectl describe replicaset <rs>
kubectl describe pvc <pvc>
kubectl describe pv <pv>
kubectl describe secret <secret>
kubectl describe configmap <cm>
kubectl describe ingress <ingress>
kubectl describe networkpolicy <policy>
kubectl describe serviceaccount <sa>
kubectl describe role <role> -n <ns>
kubectl describe rolebinding <rb> -n <ns>
```

---

## Creating Resources

```bash
# From file
kubectl apply -f <file.yaml>
kubectl apply -f <directory>/
kubectl create -f <file.yaml>

# Pods
kubectl run <name> --image=<image>
kubectl run <name> --image=<image> --labels="app=web,env=prod"
kubectl run <name> --image=<image> --port=80
kubectl run <name> --image=<image> --env="KEY=value"
kubectl run <name> --image=busybox -- sleep 3600

# Deployments
kubectl create deployment <name> --image=<image>
kubectl create deployment <name> --image=<image> --replicas=3

# Services
kubectl expose pod <pod> --port=80 --target-port=8080
kubectl expose deployment <deploy> --port=80 --target-port=8080 --type=ClusterIP
kubectl expose deployment <deploy> --port=80 --type=NodePort
kubectl expose deployment <deploy> --port=80 --type=LoadBalancer

# ConfigMaps
kubectl create configmap <name> --from-literal=key=val
kubectl create configmap <name> --from-literal=k1=v1 --from-literal=k2=v2
kubectl create configmap <name> --from-file=config.properties

# Secrets
kubectl create secret generic <name> --from-literal=key=val
kubectl create secret tls <name> --cert=cert.crt --key=key.key
kubectl create secret docker-registry <name> \
  --docker-server=<registry> \
  --docker-username=<user> \
  --docker-password=<pass>

# Namespaces, RBAC, ServiceAccounts
kubectl create namespace <name>
kubectl create serviceaccount <name> -n <ns>
kubectl create role <name> --verb=get,list,watch --resource=pods -n <ns>
kubectl create rolebinding <name> --role=<role> --user=<user> -n <ns>
kubectl create rolebinding <name> --role=<role> --serviceaccount=<ns>:<sa> -n <ns>
kubectl create clusterrole <name> --verb=get,list,watch --resource=pods,nodes
kubectl create clusterrolebinding <name> --clusterrole=<role> --user=<user>

# Dry run — generate YAML without creating
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml
kubectl create deployment web --image=nginx --dry-run=client -o yaml > deploy.yaml
kubectl create configmap my-cm --from-literal=key=val --dry-run=client -o yaml > cm.yaml
kubectl expose deployment web --port=80 --dry-run=client -o yaml > svc.yaml
```

---

## Updating Resources

```bash
# Edit live resource (opens $EDITOR)
kubectl edit <resource> <name>
kubectl edit <resource> <name> -n <ns>

# Set image (triggers rolling update on Deployments)
kubectl set image deployment/<deploy> <container>=<image>
kubectl set image deployment/<deploy> <container>=<image>:<tag>

# Scale
kubectl scale deployment <deploy> --replicas=5
kubectl scale rs <rs> --replicas=3

# Patch inline (JSON merge)
kubectl patch deployment <deploy> -p '{"spec":{"replicas":5}}'
kubectl patch svc <svc> -p '{"spec":{"type":"NodePort"}}'

# Labels
kubectl label pod <pod> env=prod
kubectl label pod <pod> env=prod --overwrite
kubectl label pod <pod> env-                          # Remove label
kubectl label node <node> disktype=ssd
kubectl label node <node> disktype-                   # Remove label

# Annotations
kubectl annotate pod <pod> description="my pod"
kubectl annotate pod <pod> description-               # Remove annotation

# Rollout commands
kubectl rollout status deployment/<deploy>
kubectl rollout history deployment/<deploy>
kubectl rollout undo deployment/<deploy>
kubectl rollout undo deployment/<deploy> --to-revision=2
kubectl rollout pause deployment/<deploy>
kubectl rollout resume deployment/<deploy>
kubectl rollout restart deployment/<deploy>

# Autoscale
kubectl autoscale deployment <deploy> --min=2 --max=10 --cpu-percent=50
```

---

## Deleting Resources

```bash
kubectl delete pod <pod>
kubectl delete deployment <deploy>
kubectl delete svc <svc>
kubectl delete namespace <ns>           # Deletes everything inside
kubectl delete -f <file.yaml>
kubectl delete pod <pod> --force --grace-period=0   # Immediate
kubectl delete pods -l app=web          # By label
kubectl delete rs <rs> --cascade=orphan # Keep pods, delete RS
```

---

## Pod Logs

```bash
kubectl logs <pod>
kubectl logs <pod> -c <container>       # Specific container
kubectl logs <pod> --previous           # Previous (crashed) container
kubectl logs <pod> -f                   # Stream/follow
kubectl logs <pod> --tail=50            # Last N lines
kubectl logs <pod> --since=1h           # Since duration
kubectl logs <pod> --since-time=<ts>    # Since timestamp
kubectl logs -l app=web                 # By label selector
kubectl logs -l app=web --all-containers # All containers in matched pods
```

---

## Exec, Port-Forward & Copy

```bash
# Shell into pod
kubectl exec -it <pod> -- /bin/sh
kubectl exec -it <pod> -- /bin/bash
kubectl exec -it <pod> -c <container> -- /bin/sh   # Specific container

# Single command
kubectl exec <pod> -- env
kubectl exec <pod> -- cat /etc/config/key
kubectl exec <pod> -- id                           # Check running user

# Port forward
kubectl port-forward pod/<pod> 8080:80
kubectl port-forward svc/<service> 8080:80
kubectl port-forward deployment/<deploy> 8080:80

# Copy files
kubectl cp <pod>:/path/to/file /local/path
kubectl cp /local/file <pod>:/remote/path
kubectl cp <pod>:/path /local/path -c <container>
```

---

## Debugging & Temporary Pods

```bash
# BusyBox — DNS, wget, nc (use 1.28 for working nslookup)
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never -- sh

# curl
kubectl run debug --image=curlimages/curl --rm -it --restart=Never -- sh

# nicolaka/netshoot — full network toolkit
kubectl run debug --image=nicolaka/netshoot --rm -it --restart=Never -- sh

# Test DNS resolution
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup <service>
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never \
  -- nslookup <service>.<namespace>.svc.cluster.local

# Test HTTP connectivity
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never \
  -- wget -qO- http://<service>:<port>

# Test TCP reachability
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never \
  -- nc -zv <service> <port>
```

---

## Resource Usage (Metrics)

```bash
kubectl top nodes
kubectl top pods
kubectl top pods -A
kubectl top pods --containers
kubectl top pods -l app=web
```

---

## Events

```bash
# All events in namespace
kubectl get events
kubectl get events -n <namespace>
kubectl get events -A
kubectl get events --sort-by=.lastTimestamp

# Events for a specific resource
kubectl get events --field-selector involvedObject.name=<pod>
kubectl get events --field-selector involvedObject.kind=Node
kubectl get events --field-selector involvedObject.kind=Pod -n <ns>
```

---

## RBAC & Auth

```bash
# Test permissions
kubectl auth can-i create pods
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'                                        # Check admin
kubectl auth can-i list secrets --as system:serviceaccount:dev:my-sa

# Create role/binding
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding alice --role=pod-reader --user=alice -n dev
kubectl create clusterrole reader --verb=get,list --resource=pods,nodes
kubectl create clusterrolebinding alice-reader --clusterrole=reader --user=alice

# ServiceAccount token
kubectl create token <sa> -n <ns>
kubectl create token <sa> -n <ns> --duration=8760h

# View roles
kubectl get roles,rolebindings -n dev
kubectl get clusterroles,clusterrolebindings
kubectl describe role <role> -n <ns>
kubectl describe rolebinding <rb> -n <ns>
```

---

## Taints, Labels & Node Management

```bash
# Labels
kubectl label node worker-1 disktype=ssd
kubectl label node worker-1 disktype-              # Remove
kubectl get nodes --show-labels
kubectl get pods --show-labels

# Taints
kubectl taint nodes node1 key=val:NoSchedule
kubectl taint nodes node1 key=val:NoSchedule-      # Remove
kubectl taint nodes node1 key=val:NoExecute
kubectl describe node node1 | grep Taint

# Cordon / Drain / Uncordon
kubectl cordon node1
kubectl drain node1 --ignore-daemonsets --delete-emptydir-data
kubectl drain node1 --ignore-daemonsets --delete-emptydir-data --force
kubectl uncordon node1

# Check what's on a node before draining
kubectl get pods --field-selector spec.nodeName=<node> -A
```

---

## Storage

```bash
# PVs and PVCs
kubectl get pv
kubectl get pvc
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc> -n <namespace>

# Check what PV a PVC is bound to
kubectl get pvc <pvc> -o jsonpath='{.spec.volumeName}'

# StorageClass
kubectl get storageclass
kubectl get sc

# Resize PVC (StorageClass must allow expansion)
kubectl patch pvc <pvc> -p '{"spec":{"resources":{"requests":{"storage":"20Gi"}}}}'
```

---

## Networking

```bash
# Services and endpoints
kubectl get svc -A
kubectl describe svc <svc> -n <ns>
kubectl get endpoints <svc> -n <ns>          # Empty = selector mismatch

# Ingress
kubectl get ingress -A
kubectl describe ingress <ingress> -n <ns>

# NetworkPolicy
kubectl get networkpolicy -n <ns>
kubectl describe networkpolicy <policy> -n <ns>

# DNS — check /etc/resolv.conf inside a pod
kubectl exec -it <pod> -- cat /etc/resolv.conf

# CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get endpoints kube-dns -n kube-system
kubectl logs -n kube-system -l k8s-app=kube-dns

# kube-proxy
kubectl get pods -n kube-system -l k8s-app=kube-proxy
kubectl logs -n kube-system -l k8s-app=kube-proxy
```

---

## Cluster Info & Health

```bash
kubectl cluster-info
kubectl get componentstatuses
kubectl get nodes -o wide
kubectl get pods -n kube-system
kubectl version
kubectl api-resources
kubectl api-resources --api-group=apps
kubectl api-versions
kubectl explain <resource>
kubectl explain <resource>.<field>
kubectl explain pod.spec.containers.securityContext
```

---

## Kubeconfig

```bash
# View
kubectl config view
kubectl config view --raw
kubectl config get-contexts
kubectl config current-context

# Switch
kubectl config use-context <context>

# Set namespace
kubectl config set-context --current --namespace=<ns>

# Add context
kubectl config set-context <name> --cluster=<c> --user=<u> --namespace=<ns>

# Merge multiple kubeconfigs
export KUBECONFIG=~/.kube/config:~/.kube/other-config
kubectl config view --merge --flatten > ~/.kube/merged-config
```

---

## Output Formats Reference

| Format | Usage |
|---|---|
| `-o yaml` | Full resource YAML |
| `-o json` | Full resource JSON |
| `-o wide` | Additional columns (node, IP) |
| `-o name` | Resource names only |
| `-o jsonpath='<expr>'` | Extract specific fields |
| `-o custom-columns=COL:.path` | Custom column output |
| `-o go-template` | Go template output |

---

## Common Flags Reference

| Flag | Purpose |
|---|---|
| `-n <namespace>` | Target namespace |
| `-A` / `--all-namespaces` | All namespaces |
| `-l <selector>` | Filter by label |
| `--field-selector` | Filter by field value |
| `--dry-run=client` | Test without applying |
| `-o yaml` | Output as YAML |
| `-w` | Watch for changes |
| `--force` | Force operation |
| `--grace-period=0` | Immediate deletion |
| `--show-labels` | Show labels column |
| `-f <file>` | Apply from file |
| `--record` | Record command in annotation (deprecated) |
| `--as <user>` | Impersonate user |
| `--as system:serviceaccount:<ns>:<sa>` | Impersonate ServiceAccount |

---

## Related Notes

- [[kubectl]] — Conceptual overview and core patterns
- [[Imperative Commands]] — All creation shortcuts with examples
- [[Exam Cheatsheet]] — Exam-focused quick reference with YAML snippets
- [[Kubeconfig]] — Context and authentication management
- [[RBAC]] — Auth testing with `kubectl auth can-i`
- [[Services]] — Endpoint verification commands
- [[Network Troubleshooting]] — DNS and connectivity debug commands
- [[Node Troubleshooting]] — Node-level diagnosis workflow
- [[OS Upgrade]] — Cordon, drain, uncordon sequence
