---
tags: [cka, reference]
aliases: [CKA Cheatsheet, Exam Quick Reference, CKA Tips]
---

# Exam Cheatsheet

> **Exam Domain**: All — quick access for exam conditions
> **Related**: [[kubectl Quick Reference]], [[Troubleshooting Guide]], [[Imperative Commands]], [[Backup]], [[RBAC]]

## Day-of Pre-flight Checklist

Run these the moment you start each task:

```bash
# 1. Set alias
alias k=kubectl

# 2. Check which cluster you are on
kubectl config current-context
kubectl config get-contexts

# 3. Switch to the correct context (task will tell you)
kubectl config use-context <context>

# 4. Set namespace shortcut if the task specifies one
kubectl config set-context --current --namespace=<ns>

# 5. Verify before any destructive command
kubectl config current-context
```

> [!warning] Wrong context = wrong cluster
> Always run `kubectl config current-context` before every task. Deploying to production while thinking you're in dev is an instant fail.

---

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

---

## etcd Backup & Restore (Exam Essential)

> [!tip] Exam Tip
> Memorise this command pattern cold — it will be on the exam. Always set `ETCDCTL_API=3` and always supply all three TLS flags.

```bash
# BACKUP
ETCDCTL_API=3 etcdctl snapshot save /opt/snapshot.db \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key

# VERIFY
ETCDCTL_API=3 etcdctl snapshot status /opt/snapshot.db

# RESTORE — Step 1: restore to new data directory
ETCDCTL_API=3 etcdctl snapshot restore /opt/snapshot.db \
  --data-dir=/var/lib/etcd-from-backup

# RESTORE — Step 2: update etcd static pod manifest
# Edit /etc/kubernetes/manifests/etcd.yaml
# Change: --data-dir=/var/lib/etcd-from-backup
# Also update the hostPath volume:
#   volumes:
#   - hostPath:
#       path: /var/lib/etcd-from-backup
#     name: etcd-data

# RESTORE — Step 3: verify cluster recovered
kubectl get nodes
kubectl get pods -A
```

---

## RBAC Quick Creation

```bash
# Role + Binding (namespaced)
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev
kubectl create rolebinding alice-reader --role=pod-reader --user=alice -n dev

# ClusterRole + Binding (cluster-wide)
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding alice-node --clusterrole=node-reader --user=alice

# Test permissions
kubectl auth can-i create pods --as alice -n dev
kubectl auth can-i '*' '*'   # Check admin

# Test as a ServiceAccount
kubectl auth can-i list pods \
  --as system:serviceaccount:dev:my-sa -n dev
```

---

## ServiceAccount Quick Reference

```bash
# Create SA
kubectl create serviceaccount my-sa -n dev

# Assign to a Pod (spec level, not container level)
# spec:
#   serviceAccountName: my-sa

# Disable token automount (security best practice)
# spec:
#   automountServiceAccountToken: false

# Generate a short-lived token
kubectl create token my-sa -n dev

# Attach imagePullSecrets to SA
kubectl patch serviceaccount my-sa -n dev \
  -p '{"imagePullSecrets": [{"name": "regcred"}]}'
```

---

## Node Maintenance

```bash
# Cordon — no new pods
kubectl cordon node01

# Drain — evict all pods safely
kubectl drain node01 --ignore-daemonsets --delete-emptydir-data

# ... do OS upgrade / maintenance ...

# Uncordon — return to service
kubectl uncordon node01

# Check what is running on a node before draining
kubectl get pods --field-selector spec.nodeName=node01 -A
```

---

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

# Role
kubectl create role pod-reader --verb=get,list,watch --resource=pods -n dev \
  --dry-run=client -o yaml > role.yaml

# CronJob
kubectl create cronjob my-cron --image=busybox --schedule="*/5 * * * *" \
  --dry-run=client -o yaml -- echo hello > cronjob.yaml
```

---

## Quick Pod Debug

```bash
# Core diagnostic trio
kubectl get pod <pod> -n <ns>
kubectl describe pod <pod> -n <ns>    # → Events section first
kubectl logs <pod> -n <ns> --previous # → crash logs

# Exec into running container
kubectl exec -it <pod> -n <ns> -- /bin/sh

# Multi-container pod — specify container
kubectl logs <pod> -n <ns> -c <container>
kubectl exec -it <pod> -n <ns> -c <container> -- /bin/sh

# Test DNS and connectivity from inside cluster
kubectl run debug --image=busybox:1.28 --rm -it --restart=Never -- sh
# Then: nslookup <svc>, wget -qO- http://<svc>:<port>, nc -zv <svc> <port>
```

---

## Application Failure Quick Chain

```bash
# 1. Pod running?
kubectl get pods -n <ns>

# 2. Events and config issues?
kubectl describe pod <pod> -n <ns>

# 3. App logs?
kubectl logs <pod> -n <ns> [--previous]

# 4. Service selecting pods? (EMPTY = selector mismatch)
kubectl get endpoints <svc> -n <ns>

# 5. Port mapping correct?
kubectl describe svc <svc> -n <ns>   # check port vs targetPort

# 6. NetworkPolicy blocking?
kubectl get networkpolicy -n <ns>

# 7. Ingress routing correct?
kubectl describe ingress <ing> -n <ns>

# 8. ConfigMap / Secret missing?
kubectl get configmap,secret -n <ns>
```

---

## Control Plane Failure Quick Chain

```bash
# 1. Can kubectl reach the cluster?
kubectl cluster-info

# 2. Are control plane pods running?
kubectl get pods -n kube-system

# 3. Static pod manifests present?
ls /etc/kubernetes/manifests/

# 4. kubelet healthy on control-plane node?
systemctl status kubelet
journalctl -u kubelet -n 50

# 5. Component logs (when kubectl works)
kubectl logs kube-apiserver-<node> -n kube-system
kubectl logs kube-scheduler-<node> -n kube-system
kubectl logs kube-controller-manager-<node> -n kube-system

# 6. Component logs (when kubectl is DOWN — use crictl)
crictl ps -a
crictl logs <container-id>

# 7. Certificates expired?
kubeadm certs check-expiration
```

| Symptom | Broken Component |
|---|---|
| `kubectl` times out | [[kube-apiserver]] |
| All new Pods stay `Pending` | [[kube-scheduler]] |
| Deployments not reconciling | [[kube-controller-manager]] |
| Cluster read-only | [[etcd]] |
| Static pods not starting | [[kubelet]] |

---

## crictl Quick Reference

Use when `kubectl` is unavailable (API server down):

```bash
# List all containers including failed ones
crictl ps -a

# Get container logs
crictl logs <container-id>
crictl logs --tail=50 <container-id>

# Exec into a running container
crictl exec -it <container-id> /bin/sh

# List images cached on node
crictl images

# Check runtime health
crictl info

# Remove unused images (disk cleanup)
crictl rmi --prune
```

---

## Static Pods

```bash
# Manifest directory (memorise this path)
/etc/kubernetes/manifests/

# Create static pod — place file here, kubelet picks it up automatically
cp my-pod.yaml /etc/kubernetes/manifests/

# Delete static pod — remove the file
rm /etc/kubernetes/manifests/my-pod.yaml

# Edit a control plane component — edit the manifest directly
vi /etc/kubernetes/manifests/kube-apiserver.yaml
# kubelet detects the change and restarts the pod automatically

# Find manifest path from kubelet config
ps aux | grep kubelet | grep manifest
cat /var/lib/kubelet/config.yaml | grep staticPodPath
```

---

## Certificate Management

```bash
# Check all certificate expiration dates
kubeadm certs check-expiration

# Renew all certificates
kubeadm certs renew all

# Inspect a specific cert
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text -noout \
  | grep -E "Subject:|Not After"

# After renewal — force restart static pods by moving manifests
mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/
sleep 5
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/
```

---

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
  storageClassName: ""   # empty = static binding only
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
  storageClassName: ""   # must match PV exactly
```

```bash
# Check PVC binding status
kubectl get pvc -n <namespace>
kubectl describe pvc <pvc> -n <namespace>   # Events show why it's Pending

# Check PV status
kubectl get pv
```

---

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
# Allow specific ingress traffic
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

> [!warning] Always allow DNS egress
> If you write an egress policy, include this or Pods lose DNS resolution:

```yaml
egress:
- to:
  - namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: kube-system
  ports:
  - protocol: UDP
    port: 53
  - protocol: TCP
    port: 53
```

---

## Scheduling Quick Reference

```bash
# Label a node
kubectl label node worker-1 disktype=ssd

# Taint a node
kubectl taint nodes node1 key=value:NoSchedule

# Remove taint (trailing dash)
kubectl taint nodes node1 key=value:NoSchedule-

# Cordon — prevent new pods
kubectl cordon node1

# Check why pod is Pending
kubectl describe pod <pod> | grep -A5 Events
kubectl get pods --field-selector=status.phase=Pending
```

```yaml
# nodeSelector (simple)
spec:
  nodeSelector:
    disktype: ssd

# Toleration
spec:
  tolerations:
  - key: "key"
    operator: "Equal"
    value: "value"
    effect: "NoSchedule"
```

---

## ConfigMap & Secret Quick Reference

```bash
# Create ConfigMap
kubectl create configmap app-config \
  --from-literal=LOG_LEVEL=debug \
  --from-literal=API_URL=https://api.example.com

# Create Secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=S3cur3P@ss

# Decode a secret value
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d

# Create docker-registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=user \
  --docker-password=pass
```

```yaml
# Consume ConfigMap as env vars
envFrom:
- configMapRef:
    name: app-config

# Consume Secret as env var
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

---

## Security Context Quick Reference

```yaml
# Pod-level + container-level (most secure pattern)
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: [ALL]
        add: [NET_BIND_SERVICE]   # only if needed
```

```bash
# Check what user a container is running as
kubectl exec -it <pod> -- id

# Verify filesystem is read-only
kubectl exec -it <pod> -- touch /test-file   # should fail
```

---

## Rollout Quick Reference

```bash
# Update image (triggers rolling update)
kubectl set image deployment/web nginx=nginx:1.26

# Check rollout status
kubectl rollout status deployment/web

# View history
kubectl rollout history deployment/web

# Rollback to previous version
kubectl rollout undo deployment/web

# Rollback to specific revision
kubectl rollout undo deployment/web --to-revision=2

# Restart all pods (e.g. after ConfigMap change)
kubectl rollout restart deployment/web
```

---

## Useful Field Selectors & JSONPath

```bash
# Get pods on a specific node
kubectl get pods --field-selector spec.nodeName=worker-1 -A

# Get running pods only
kubectl get pods --field-selector status.phase=Running -A

# Extract specific field with jsonpath
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].image}'
kubectl get nodes -o jsonpath='{.items[*].metadata.name}'

# Get pod IP
kubectl get pod <pod> -o jsonpath='{.status.podIP}'

# Get all container names in a pod
kubectl get pod <pod> -o jsonpath='{.spec.containers[*].name}'
```

---

## Related Notes

- [[kubectl Quick Reference]] — All kubectl commands in one place
- [[Troubleshooting Guide]] — Systematic top-down diagnosis workflow
- [[Imperative Commands]] — All creation shortcuts
- [[Application Failure Troubleshooting]] — Full app debug chain
- [[Control Plane Failure Troubleshooting]] — Control plane diagnosis with crictl
- [[Backup]] — Full etcd backup and restore procedure
- [[RBAC]] — Role, binding, and permission testing
- [[Network Policy]] — Default deny and egress DNS rule patterns
- [[OS Upgrade]] — Cordon, drain, and uncordon workflow
- [[crictl]] — Container runtime CLI for node-level debugging
