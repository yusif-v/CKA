## Overview

A **Pod** is the smallest deployable unit in Kubernetes, representing **one or more tightly coupled containers** that share networking, storage, and a specification for how to run them. Pods abstract container management so Kubernetes can schedule and maintain workloads.

Pods are **ephemeral** and are intended to be replaced, not updated directly.

## Pod Anatomy

- **Containers**: One or more container images running together
- **Shared Networking**: Single IP, port space, localhost communication
- **Shared Storage**: Volumes mounted across containers
- **PodSpec**: Desired state definition
- **PodStatus**: Current state reported by kubelet

## Lifecycle Phases

1. **Pending** – Scheduled but not running
2. **ContainerCreating** – Containers being created
3. **Running** – At least one container is running
4. **Succeeded** – All containers completed successfully
5. **Failed** – At least one container failed
6. **Unknown** – Node unreachable

## Core Features

- **Resource Requests and Limits** – CPU, memory
- **Environment Variables** – Config via env or ConfigMap/Secret
- **Labels and Annotations** – Metadata for selection and identification
- **Restart Policy** – Always, OnFailure, Never
- **Probes** – Liveness, Readiness, Startup

## Interaction with Components

- **[[kubelet]]** – Executes containers, mounts volumes, reports status
- **[[kube-scheduler]]** – Assigns Pod to a Node
- **[[kube-apiserver]]** – Source of truth for PodSpec
- **[[kube-proxy]] / Networking** – Routes traffic to Pod IP

## Volumes and Storage

- Can mount **emptyDir**, **ConfigMap**, **Secret**, **PersistentVolumeClaim**
- Volumes are shared across containers in the Pod
- Ephemeral by default unless backed by PersistentVolume

## Networking

- All containers share Pod IP
- Communicate via localhost internally
- Exposed externally via **Services**
- Subject to **NetworkPolicies**

## Pod Templates

- Used in **ReplicaSet**, **Deployment**, **Job**, **StatefulSet**
- Define standard PodSpec for scalable workloads

## Probes

- **Liveness Probe** – Restarts unhealthy container
- **Readiness Probe** – Controls Service endpoints
- **Startup Probe** – Handles slow-start containers

## Troubleshooting

- Pod stuck Pending → scheduling, resources, affinity, taints
- Container crash loops → check logs, probes, image, commands
- Volume mount errors → CSI/hostPath issues
- Networking issues → Service, CNI, or kube-proxy