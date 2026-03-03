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

---

## 01 — Architecture

- [[Cluster Architecture]] — Full cluster overview
- [[kube-apiserver]] — Central hub, all traffic goes through here
- [[etcd]] — Cluster state store, critical for backup/restore
- [[kube-scheduler]] — Pod-to-Node assignment
- [[kube-controller-manager]] — Reconciliation engine
- [[kubelet]] — Node agent
- [[kube-proxy]] — Service networking on nodes
- [[Static Pods]] — Node-level pods managed by kubelet

## 02 — Cluster Setup

- [[kubeadm]] — Bootstrap and lifecycle tool
- [[minikube]] — Local development cluster
- [[Kubeconfig]] — Connection and auth configuration

## 03 — CLI Tools

- [[kubectl]] — Primary CLI for all operations
- [[Imperative Commands]] — Fast exam commands
- [[etcdctl]] — etcd client for backup/restore
- [[etcdutl]] — Offline etcd data tool
- [[API Groups]] — Understanding Kubernetes API structure

## 04 — Workloads

- [[Pods]] — Smallest deployable unit
- [[Multi-Container Pods]] — Sidecars, adapters, ambassadors
- [[Init Containers]] — Pre-startup setup containers
- [[Deployments]] — Stateless app management
- [[DaemonSets]] — One Pod per node

## 05 — Scheduling

- [[Scheduling]] — How Pods get assigned to Nodes
- [[Node Affinity]] — Advanced node selection
- [[Taints]] — Node-level repulsion
- [[Labels]] — Key-value identity system
- [[Autoscaling]] — HPA, VPA, Cluster Autoscaler
- [[Vertical Pod Autoscaler]] — Per-pod resource tuning

## 06 — Networking

- [[Services]] — Stable network endpoints
- [[Ingress]] — HTTP/HTTPS routing
- [[Network Policy]] — Pod-level firewall rules
- [[Namespaces]] — Cluster partitioning
- [[Network Namespaces]] — Linux-level network isolation
* [[Gateway API]] — Official Ingress successor, multi-protocol routing

## 07 — Storage

- [[Storage Class]] — Dynamic provisioning templates
- [[Persistent Volumes]] — Cluster-level storage resources
- [[Persistent Volume Claims]] — Storage requests from Pods

## 08 — Configuration

- [[ConfigMap]] — Non-sensitive configuration
- [[Secrets]] — Sensitive data storage
- [[Environment Variables]] — Runtime config injection
- [[Resource Limits]] — CPU/memory enforcement

## 09 — Security

- [[RBAC]] — Role-based access control
- [[TLS in Kubernetes]] — Certificate-driven security
- [[Security Contexts]] — Container privilege model
- [[Image Security]] — Supply chain and registry security
- [[Custom Resource Definition]] — API extensions

## 10 — Operations

- [[OS Upgrade]] — Safe node maintenance
- [[Backup]] — etcd snapshot and restore

## 11 — Troubleshooting

- [[Troubleshooting Guide]] — Master troubleshooting workflow
- [[Node Troubleshooting]] — Node-level diagnosis
- [[Pod Troubleshooting]] — Pod and container diagnosis

## 12 — Reference

- [[Exam Cheatsheet]] — Quick-access exam commands
- [[kubectl Quick Reference]] — All kubectl commands in one place
