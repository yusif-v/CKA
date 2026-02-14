# Custom Resource Definition (CRD)
## Overview  

A **Custom Resource Definition (CRD)** allows you to extend the Kubernetes API by creating your own resource types.

It enables Kubernetes to manage application-specific objects the same way it manages built-in resources like Pods or Deployments.

CRDs are commonly used to build **Operators** and automate complex systems.

## Why Use CRDs?

CRDs are useful when you need Kubernetes to understand and manage domain-specific concepts such as:
- Databases
- Message brokers
- Backups
- Monitoring stacks
- Custom applications with lifecycle logic

Instead of scripting deployments manually, you define the desired state declaratively.

## How CRDs Work

1. You define a new resource type using a CRD.
2. Kubernetes API Server accepts this new type.
3. Objects of this type are stored in etcd.
4. A **controller/operator** watches these objects.
5. The controller reconciles the actual state to match the declared state.

CRD = Schema + API Extension

Controller = Logic that makes it functional

## Example CRD

```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: apps.platform.example.com

spec:
  group: platform.example.com

  names:
    kind: App
    plural: apps
    singular: app
    shortNames:
      - ap

  scope: Namespaced

  versions:
    - name: v1
      served: true
      storage: true

      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                image:
                  type: string
                replicas:
                  type: integer
```

## Example Custom Resource

After applying the CRD, you can create objects of that type:

```yaml
apiVersion: platform.example.com/v1
kind: App
metadata:
  name: my-nginx
spec:
  image: nginx:latest
  replicas: 3
```

## Key CRD Fields

|**Field**|**Description**|
|---|---|
|group|API namespace for the custom resource|
|versions|Supports API versioning|
|names|Defines how the resource is referenced|
|scope|Namespaced or Cluster|
|schema|Validation rules using OpenAPI|
|served|Makes version accessible via API|
|storage|Version used for persistence|

## Useful Commands

```bash
kubectl get crd
kubectl describe crd <crd-name>
kubectl api-resources | grep <resource>
kubectl get <custom-resource>
```

## CRD vs Built-in Resource

|**Feature**|**Built-in Resource**|**CRD**|
|---|---|---|
|Defined by|Kubernetes|User|
|API Extension|No|Yes|
|Requires Controller|Already implemented|Must be added|
|Use Case|Core workloads|Platform automation|

## Important Note

Creating a CRD alone does **not** provide automation.
A controller/operator must watch the resource and act on it.

Without a controller, CRDs only store structured data.

## When to Use CRDs
  
Use CRDs when:
- You need reusable infrastructure abstractions.
- You want Kubernetes-native automation.
- You are building a platform or operator.

Avoid CRDs when:
- A simple Deployment or Helm chart is enough.
- No reconciliation logic is required.

## Summary

CRDs extend Kubernetes into a customizable platform by allowing you to define and manage your own resource types declaratively, enabling advanced automation through controllers and Operators.