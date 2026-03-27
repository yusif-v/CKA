---
tags: [cka, index, moc]
aliases: [CKA Index, Kubernetes Exam, CKA Home]
---

# CKA — Certified Kubernetes Administrator

> **Map of Content** — Start here. Navigate to any domain below.

## Exam Domains & Weights

| Domain | Weight | Folder |
|---|---|---|
| Cluster Architecture, Installation & Configuration | 25% | 01-Architecture |
| Workloads & Scheduling | 15% | 04-Workloads + 05-Scheduling |
| Services & Networking | 20% | 06-Networking |
| Storage | 10% | 07-Storage |
| Troubleshooting | 30% | 11-Troubleshooting |

> [!warning] Priority
> Troubleshooting is **30% of the exam**. Make [[Troubleshooting Guide]] your most-reviewed note.

> [!tip] Exam Prep
> Labs, scenarios, and scripts live in [[12-Labs/README|12-Labs]]. Use these for hands-on practice before the exam.

---

## 01 — Architecture

- [[Cluster Architecture]] — Full cluster overview and component relationships
- [[kube-apiserver]] — Central hub; all traffic flows through here
- [[etcd]] — Cluster state store; critical for backup and restore
- [[kube-scheduler]] — Pod-to-Node assignment logic
- [[kube-controller-manager]] — Reconciliation engine; runs all built-in controllers
- [[kubelet]] — Node agent; manages Pod lifecycle on each node
- [[kube-proxy]] — Service networking rules on every node
- [[Static Pods]] — Node-level Pods managed directly by kubelet

## 02 — Cluster Setup

- [[kubeadm]] — Bootstrap, upgrade, and certificate lifecycle tool
- [[minikube]] — Local single-node development cluster
- [[Kubeconfig]] — Connection, context, and authentication configuration
- [[Addons]] — CNI, CoreDNS, metrics-server and other required cluster extensions

## 03 — CLI Tools

- [[kubectl]] — Primary CLI for all cluster operations
- [[Imperative Commands]] — Fast exam command patterns; dry-run YAML generation
- [[etcdctl]] — Live etcd client for backup and restore
- [[etcdutl]] — Offline etcd data inspection and restore tool
- [[API Groups]] — Kubernetes API versioning and resource group structure
- [[Helm]] — Kubernetes package manager; charts, releases, and lifecycle
- [[Kustomize]] — Template-free config management with base/overlay pattern; built into kubectl
- [[crictl]] — CRI command-line tool; direct container runtime access when kubectl is unavailable; node-level container and image inspection
## 04 — Workloads

- [[Pods]] — Smallest deployable unit; lifecycle, probes, volumes
- [[Multi-Container Pods]] — Sidecar, adapter, and ambassador patterns
- [[Init Containers]] — Pre-startup setup containers; sequencing and handoff
- [[Deployments]] — Stateless app management; rolling updates and rollbacks
- [[DaemonSets]] — One Pod per node; node-level infrastructure workloads
- [[ReplicaSets]] — Pod count enforcement; Deployment internals
- [[Jobs and CronJobs]] — Finite batch tasks (Job) and scheduled execution (CronJob)

## 05 — Scheduling

- [[Scheduling]] — How Pods get assigned to Nodes; filtering and scoring phases
- [[Node Affinity]] — Advanced label-based node selection; required and preferred rules
- [[Taints]] — Node-level Pod repulsion; NoSchedule, NoExecute, PreferNoSchedule
- [[Labels]] — Key-value identity system; selectors for Services, Deployments, policies
- [[Autoscaling]] — HPA, VPA, and Cluster Autoscaler overview
- [[Vertical Pod Autoscaler]] — Per-pod resource tuning; recommendations and auto mode

## 06 — Networking

- [[Services]] — Stable virtual network endpoints; ClusterIP, NodePort, LoadBalancer
- [[Ingress]] — HTTP/HTTPS routing and TLS termination
- [[Gateway API]] — Official Ingress successor; multi-protocol, role-oriented routing
- [[Network Policy]] — Pod-level firewall rules; ingress and egress control
- [[Namespaces]] — Cluster partitioning; resource scoping and DNS isolation
- [[Network Namespaces]] — Linux kernel-level network isolation; foundation for Pod networking
- [[CoreDNS]] — Cluster DNS server; Service name resolution, Corefile config, troubleshooting
- [[CNI Plugins]] — Pod networking layer; Flannel vs Calico vs Cilium, installation, CIDR config

## 07 — Storage

- [[Storage Class]] — Dynamic provisioning templates; reclaim policies and binding modes
- [[Persistent Volumes]] — Cluster-level storage resources; static and dynamic provisioning
- [[Persistent Volume Claims]] — Storage requests from Pods; binding, access modes, resizing

## 08 — Configuration

- [[ConfigMap]] — Non-sensitive configuration; env vars and volume mounts
- [[Secrets]] — Sensitive data storage; base64 encoding, types, and best practices
- [[Environment Variables]] — Runtime config injection; literals, ConfigMaps, Secrets, Downward API
- [[Resource Limits]] — CPU and memory requests/limits; QoS classes, LimitRange, ResourceQuota

## 09 — Security

- [[RBAC]] — Role-based access control; Roles, ClusterRoles, bindings, and testing
- [[TLS in Kubernetes]] — Certificate-driven security; PKI layout, renewal, and inspection
- [[Security Contexts]] — Container privilege model; runAsUser, capabilities, seccomp
- [[Image Security]] — Supply chain and registry security; imagePullSecrets, pull policy
- [[ServiceAccounts]] — Pod identity for API authentication; token automount and RBAC binding
- [[Custom Resource Definition]] — API extensions; CRD schema, operators, and RBAC for custom resources

## 10 — Operations

- [[OS Upgrade]] — Safe node maintenance; cordon, drain, upgrade, uncordon workflow
- [[Backup]] — etcd snapshot save and restore; full procedure with TLS flags

## 11 — Troubleshooting

- [[Troubleshooting Guide]] — Master diagnostic workflow; top-down systematic approach
- [[Pod Troubleshooting]] — Pod and container diagnosis; status meanings, CrashLoopBackOff, OOMKilled
- [[Node Troubleshooting]] — Node-level diagnosis; kubelet, container runtime, disk and memory pressure
- [[Application Failure Troubleshooting]] — End-to-end app diagnosis; services, endpoints, DNS, NetworkPolicy, Ingress
- [[Control Plane Failure Troubleshooting]] — kube-apiserver, etcd, scheduler, controller-manager; static pods and journalctl
- [[Network Troubleshooting]] — DNS failures, Service connectivity, empty endpoints, CNI and kube-proxy diagnosis

## 12 — Labs

## 13 — Reference

- [[Exam Cheatsheet]] — Quick-access exam commands; most tested topics and YAML snippets
- [[kubectl Quick Reference]] — All kubectl commands in one place; output formats and filters
