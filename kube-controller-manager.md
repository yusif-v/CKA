
## Overview

The kube-controller-manager runs a set of core Kubernetes controllers that continuously reconcile **desired state vs current state**. It watches the kube-apiserver for changes and takes actions to move the cluster toward the declared configuration.

All actions are performed **via the kube-apiserver**; it does not talk directly to nodes or etcd.

## Controllers

Each controller is a control loop:
- Watch objects through kube-apiserver
- Compare desired vs actual state
- Reconcile differences
- Repeat continuously (idempotent behavior)

## Key Controllers

- [[Node Controller]]
- [[Replication Controller]]
- [[ReplicaSet Controller]]
- [[Deployment Controller]]
- [[Endpoint Controller]]
- [[EndpointSlice Controller]]
- [[Namespace Controller]]
- [[ServiceAccount Controller]]
- [[Token Controller]]
- [[Job Controller]]
- [[PersistentVolume Controller]]
## Interaction with Control Plane

- Watches resources using shared informers    
- Writes updates via REST API calls
- Does **not** access etcd directly
- All controllers run in one binary but operate independently

## High Availability Behavior

- Multiple instances supported    
- Leader election ensures a single active controller
- Standby instances remain idle
- Uses Lease objects in kube-system

## **Configuration**
### **Deployment**

- Static Pod:
    /etc/kubernetes/manifests/kube-controller-manager.yaml

### **Important Flags**

- --leader-elect=true    
- --controllers=*
- --node-monitor-period
- --pod-eviction-timeout
- --use-service-account-credentials

### **Authentication & Authorization**

- Uses client certificates to authenticate    
- Authorized via RBAC
- Controller-specific ServiceAccounts supported

## **Monitoring and Health**

- /healthz    
- /metrics
- Common metrics:
    - workqueue_depth
    - controller_runtime_reconcile_total

## **Troubleshooting**

- Pods not recreated → [[ReplicaSet Controller]]
- Nodes NotReady → [[Node Controller]]
- Namespace stuck Terminating → [[Namespace Controller]] (finalizers)
