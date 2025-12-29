## Overview

The kube-scheduler is the Kubernetes control-plane component responsible for **assigning Pods to Nodes**. It watches for newly created Pods without a nodeName and selects the most suitable node based on resource availability, constraints, and scheduling policies.

The scheduler does **not** create Pods or start containers; it only writes the binding decision back to the kube-apiserver.
  
## Scheduling Workflow

1. Watch kube-apiserver for unscheduled Pods    
2. Build a list of feasible nodes
3. Score feasible nodes
4. Select the highest-scoring node
5. Bind the Pod to the chosen node via kube-apiserver

Scheduling is a **single decision**, not a continuous reconciliation loop.

## Scheduling Phases
### Filtering (Predicates)

- Removes nodes that cannot run the Pod
- Based on hard requirements
- Examples:
    - Insufficient CPU or memory
    - NodeSelector / NodeAffinity mismatch
    - Taints not tolerated
    - Port conflicts

### Scoring (Priorities)

- Ranks remaining nodes 
- Soft preferences influence scoring
- Examples:
    - Resource balance
    - Affinity preferences
    - Topology spread constraints

## Scheduling Framework

- Plugin-based architecture
- Extension points:
    - QueueSort
    - PreFilter / Filter
    - PreScore / Score
    - Reserve / Unreserve
    - Permit
    - PreBind / Bind
    - PostBind
- Allows custom scheduling behavior without replacing the scheduler

## Interaction with Control Plane

- Watches Pods via [[kube-apiserver]]
- Writes binding objects back to kube-apiserver
- Does not communicate with kubelet directly
- Does not access etcd

## High Availability Behavior

- Multiple schedulers supported
- Leader election ensures a single active scheduler
- Standby instances remain idle
- Leader election uses Lease objects in kube-system

## Configuration
### Deployment

- Runs as a static Pod
    `/etc/kubernetes/manifests/kube-scheduler.yaml`

### Important Flags

- --leader-elect=true
- --scheduler-name=default-scheduler
- --config=/etc/kubernetes/scheduler.conf
- --bind-address
- --secure-port=10259

### Scheduler Configuration File

- Defines plugin enable/disable order
- Controls scoring weights
- Supports multiple scheduling profiles

## Constraints and Signals
### Hard Constraints

- Resource requests and limits
- NodeSelector / required NodeAffinity
- Taints and Tolerations
- Volume binding requirements

### Soft Constraints

- Preferred NodeAffinity
- PodAffinity / PodAntiAffinity (preferred)
- TopologySpreadConstraints (soft)

## Monitoring and Health

- Health endpoint: /healthz
- Metrics endpoint: /metrics
- Useful metrics:
    - scheduler_schedule_attempts_total
    - scheduler_pending_pods
    - scheduler_e2e_scheduling_duration_seconds

## Troubleshooting

- Pod stuck in Pending → scheduling failure
- Check Pod events for FailedScheduling
- Verify:
    - Resource availability
    - Taints/tolerations
    - Affinity rules
- Inspect scheduler logs
- kubectl describe pod <pod>