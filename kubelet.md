
## Overview

The kubelet is the primary **node-level agent** in Kubernetes. It runs on every worker node and is responsible for ensuring that Pods assigned to the node are running and healthy, as defined by the PodSpec.

The kubelet does **not** schedule Pods and does **not** talk directly to etcd. All communication flows through the kube-apiserver.

## Core Responsibilities

- Watches kube-apiserver for Pods bound to the node
- Creates and manages containers via the container runtime
- Mounts volumes and injects secrets/configs
- Executes liveness, readiness, and startup probes
- Reports Pod and Node status

## Pod Lifecycle Management
### Pod Creation Flow

1. Pod is scheduled to the node
2. kubelet retrieves PodSpec from kube-apiserver
3. Pull images via container runtime
4. Create containers
5. Apply cgroups and namespaces
6. Start containers and probes

### Pod Termination Flow

- Receives delete request with grace period
- Sends SIGTERM to containers
- Waits for graceful shutdown
- Sends SIGKILL if timeout exceeded
## Interaction with Other Components

- Communicates with:
    - [[kube-apiserver]]
    - [[Container Runtime]] (via CRI)
    - [[CNI Plugin]]
    - [[CSI Driver]]
    
- Does **not** communicate with:
    - [[kube-scheduler]]
    - [[etcd]]
  

## Node Management

### Node Registration

- Registers the Node object on startup
- Applies labels and taints
- Maintains node leases for heartbeat

### Node Status Reporting

- Updates:
    - Node conditions
    - Capacity and allocatable resources
    - Running Pods
- Heartbeat interval controlled by leases

## Probes and Health
### Liveness Probe

- Detects dead containers
- Triggers container restart

### Readiness Probe

- Controls Service endpoint inclusion

### Startup Probe

- Used for slow-starting containers
- Disables liveness until successful

## Configuration
### Deployment

- Runs as a system service or static Pod
- Managed by systemd or kubeadm

### Configuration Sources

- Command-line flags
- Config file:
    /var/lib/kubelet/config.yaml

### Important Flags

- --config
- --kubeconfig
- --container-runtime-endpoint
- --pod-manifest-path
- --fail-swap-on
- --node-ip

## Security Model
### Authentication

- Uses client certificates to authenticate to kube-apiserver
- Supports webhook authentication for incoming requests

### Authorization

- Node Authorizer limits node permissions
- Prevents node-to-node privilege escalation

### Certificate Rotation

- Supports automatic client cert rotation
- Controlled via kubeadm and flags

## Monitoring and Logs

- Metrics endpoint: /metrics
- Node health via Node conditions
- Logs:
    - journalctl -u kubelet
    - /var/log/syslog (depending on OS)

## Troubleshooting

- Pod stuck in ContainerCreating → volume, image, or CNI issue
- Node NotReady → kubelet or runtime problem
- Check:    
    - kubelet logs
    - Node conditions
    - Pod events