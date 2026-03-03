---
tags: [cka, reference]
aliases: [CKA Cheatsheet, Exam Quick Reference, CKA Tips]
---

# Exam Cheatsheet

> **Exam Domain**: All — quick access for exam conditions
> **Related**: [[kubectl Quick Reference]], [[Troubleshooting Guide]], [[Imperative Commands]]

## Exam Environment Tips

- You have access to `kubernetes.io/docs` — use it for YAML examples
- Use `--dry-run=client -o yaml` to generate YAML scaffolds quickly
- Set your namespace shortcut early: `alias k=kubectl`
- Always check which cluster/context you're on: `kubectl config current-context`
- Use `kubectl explain <resource>.<field>` for field lookups without docs

```bash
# Set alias (saves typing)
alias k=kubectl

# Set namespace for session
kubectl config set-context --current --namespace=<ns>

# Always verify context before destructive commands
kubectl config current-context
kubectl config get-contexts
```

## Most Tested Topics (by frequency)

1. **etcd backup & restore** — `etcdctl snapshot save/restore`
2. **Drain & upgrade nodes** — `kubectl drain --ignore-daemonsets`
3. **RBAC** — create Role, RoleBinding, test with `auth can-i`
4. **Pod troubleshooting** — `describe` + `logs --previous`
5. **Static Pod paths** — `/etc/kubernetes/manifests/`
6. **Certificate expiry** — `kubeadm certs check-expiration`
7. **PV/PVC creation and binding**
8. **NetworkPolicy** — default deny + specific allow
9. **Scheduling** — taints, tolerations, nodeSelector
10. **ConfigMap/Secret** — create and consume in Pod

## etcd Backup & Restore (Exam Essential)

```bash
# BACKUP
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# VERIFY
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db

# RESTORE
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot.db \
  --data-dir=/var/lib/etcd-from-backup
# Then update /etc/kubernetes/manifests/etcd.yaml --data-dir and hostPath
```

## RBAC Quick Creation

```bash
# Role + Binding
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding alice-reader --role=pod-reader --user=alice -n dev

# ClusterRole + Binding
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding alice-node --clusterrole=node-reader --user=alice

# Test
kubectl auth can-i create pods --as alice -n dev
```

## Node Maintenance

```bash
kubectl cordon node01
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data
# ... do maintenance ...
kubectl uncordon node01
```

## YAML Generation (Dry Run)

```bash
# Pod
kubectl run nginx --image=nginx --dry-run=client -o yaml > pod.yaml

# Deployment
kubectl create deployment web --image=nginx --replicas=3 --dry-run=client -o yaml > deploy.yaml

# Service
kubectl expose deployment web --port=80 --type=NodePort --dry-run=client -o yaml > svc.yaml

# ConfigMap
kubectl create configmap my-cm --from-literal=key=val --dry-run=client -o yaml > cm.yaml

# Secret
kubectl create secret generic my-secret --from-literal=pass=abc123 --dry-run=client -o yaml > secret.yaml
```

## Quick Pod Debug

```bash
# Check why pod is failing
kubectl describe pod <pod> -n <ns>    # → Events section
kubectl logs <pod> --previous         # → crash logs

# Exec into pod
kubectl exec -it <pod> -- /bin/sh

# Test DNS/connectivity from inside cluster
kubectl run debug --image=busybox --rm -it -- sh
# Then: nslookup svc-name, wget -qO- http://svc:port
```

## Static Pods

```bash
# Location of static pod manifests
/etc/kubernetes/manifests/

# Create static pod: copy YAML here
cp my-pod.yaml /etc/kubernetes/manifests/

# Delete static pod: remove the file
rm /etc/kubernetes/manifests/my-pod.yaml

# Find manifest path from kubelet
ps aux | grep kubelet | grep manifest
```

## Certificate Management

```bash
# Check expiration
kubeadm certs check-expiration

# Renew all
kubeadm certs renew all

# Inspect cert
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout | grep -E "Subject:|Not After"
```

## PV / PVC Quick Reference

```yaml
# PersistentVolume (static)
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-local
spec:
  capacity:
    storage: 1Gi
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /mnt/data

---
# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 1Gi
  storageClassName: ""   # Match PV exactly
```

## NetworkPolicy — Default Deny + Allow

```yaml
# Default deny all in namespace
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: app
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]

---
# Allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend
  namespace: app
spec:
  podSelector:
    matchLabels:
      role: backend
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
```

## Scheduling Quick Reference

```bash
# Label a node
kubectl label node worker-1 disktype=ssd

# Taint a node
kubectl taint nodes node1 key=value:NoSchedule

# Remove taint
kubectl taint nodes node1 key=value:NoSchedule-

# Cordon (no new pods)
kubectl cordon node1

# Check why pod is Pending
kubectl describe pod <pod> | grep -A5 Events
```

## Related Notes

- [[kubectl Quick Reference]] — All kubectl commands in one place
- [[Troubleshooting Guide]] — Systematic diagnosis workflow
- [[Imperative Commands]] — All creation shortcuts
