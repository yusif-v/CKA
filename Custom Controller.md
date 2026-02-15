# Custom Controller
## Overview

A **Custom Controller** is a Kubernetes component that watches a Custom Resource (CR) and continuously reconciles the actual state of the system to match the desired state defined by that resource.

It is the **brain** behind a CRD.

CRD = Defines _what_
Controller = Implements _how_

Without a controller, a CRD is just structured data sitting in etcd.

## What is a Controller in Kubernetes?

A controller is a control loop that:
1. Watches the API Server for changes to resources.
2. Compares **desired state** vs **current state**.
3. Takes action to fix differences.

This process is called **Reconciliation**.

Kubernetes built-in controllers:
- Deployment Controller
- ReplicaSet Controller    
- Node Controller

A Custom Controller follows the exact same pattern — just for your own resources.

## How Custom Controllers Work

The controller continuously performs this loop:

```bash
Watch → Detect Change → Reconcile → Update Status → Repeat
```

Example:
You create:

```yaml
kind: App
spec:
  replicas: 3
```

Controller ensures:
- A Deployment exists
- 3 Pods are running
- If a Pod dies → recreate it
- If replicas change → scale

## Controller Responsibilities

A Custom Controller typically:
- Watches Custom Resources
- Creates/updates Kubernetes objects (Pods, Services, etc.)
- Handles scaling, upgrades, backups, failover
- Updates .status field of the resource
- Ensures idempotency (safe to run repeatedly)

## **Reconciliation Pattern (Core Concept)**

Controllers **never assume state**.

They always:
1. Read actual cluster state
2. Compare to desired state
3. Fix drift

This makes Kubernetes self-healing.

## Example Logic (Pseudo Workflow)

Custom Resource:

```yaml
kind: Database
spec:
  size: 10Gi
  replicas: 2
```

Controller Reconciliation:
- If StatefulSet doesn’t exist → create it
- If replicas mismatch → scale
- If PVC missing → create storage
- If Pod crashes → recreate
- Update .status.phase = Running

## Controller Architecture Components

|**Component**|**Purpose**|
|---|---|
|Informer|Watches API changes efficiently|
|Work Queue|Handles events reliably|
|Reconciler|Business logic|
|Client|Talks to Kubernetes API|
|Finalizers|Cleanup before deletion|

## Finalizers (Important)

Used to perform cleanup before resource deletion.

Example:
Prevent deleting a Database CR until backups are taken.

## Common Use Cases

Custom Controllers power:
- Operators (Database Operator, Kafka Operator, etc.)
- Auto-provisioning systems
- Backup/restore automation
- Security enforcement workflows
- Platform abstractions (App-as-a-Service)

## Example Controller Behavior

User applies:

```bash
kubectl apply -f my-app.yaml
```

Controller automatically:
- Creates Deployment
- Creates Service
- Injects ConfigMaps
- Manages lifecycle

User only declares intent.
Controller handles reality.

## Tools Used to Build Controllers

|**Tool**|**Purpose**|
|---|---|
|client-go|Kubernetes Go SDK|
|Kubebuilder|Framework for Operators|
|Operator SDK|Simplifies controller development|
|controller-runtime|Reconciliation framework|

## Controller vs Operator

|**Feature**|**Custom Controller**|**Operator**|
|---|---|---|
|Scope|Single automation|Full lifecycle automation|
|Complexity|Simpler|Advanced|
|Includes CRD|Optional|Always|
|Domain Knowledge|Minimal|Encoded expertise|

Operator = Controller + Domain Intelligence.

## Key Principle

Controllers must be:
- Declarative (not imperative)
- Idempotent (safe to rerun)
- Event-driven (react to changes)
- Self-healing

## Summary

A Custom Controller is the automation engine that makes Custom Resources meaningful.
It continuously reconciles declared intent with actual cluster state, enabling Kubernetes to manage complex systems automatically.