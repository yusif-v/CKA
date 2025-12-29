
## Overview

Kubernetes cluster consists of a control plane (master nodes) that manages the cluster and worker nodes that run application workloads. For high availability, deploy multiple control plane nodes.

## Components

### Control Plane

- **API Server**: Serves as the central hub for all cluster operations and communications.
- [[etcd]]: Distributed key-value store holding the cluster's configuration and state data.
- **Scheduler**: Watches for newly created pods and assigns them to appropriate nodes.
- **Controller Manager**: Oversees various controllers, such as node controller and replication controller, to maintain desired cluster state.

### Worker Nodes

- **Kubelet**: Agent that ensures containers in pods are running and healthy on the node.
- **Kube-proxy**: Maintains network rules for service abstraction and load balancing.
- **Container Runtime**: Software like containerd or CRI-O responsible for running containers.

## High Availability

- Use multiple control plane nodes with a load balancer for failover.
- Configure etcd in a clustered setup for data redundancy and consistency.