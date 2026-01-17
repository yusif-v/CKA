# Secrets
## Overview

A **Secret** is a Kubernetes object used to **store sensitive data**, such as passwords, tokens, or keys.

Secrets are similar to [[ConfigMap]]s, but are designed for **confidential information**.

## What Secrets Are Used For

Common examples include:
- Database credentials
- API tokens
- TLS certificates
- SSH keys
- Service account tokens

Secrets allow sensitive data to be **decoupled from container images**.

## Secret Types

Kubernetes supports multiple Secret types:
- Opaque (generic key-value pairs)
- kubernetes.io/dockerconfigjson
- kubernetes.io/tls
- kubernetes.io/service-account-token

Each type has a specific structure and purpose.

## Secret Definition Example

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=
  password: cGFzc3dvcmQ=
```

Values in data must be **base64-encoded**.

## Creating Secrets Imperatively

From literals:

```bash
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=passw0rd
```

From files:

```bash
kubectl create secret generic db-secret --from-file=credentials.txt
```

## Using Secrets in Pods
### As Environment Variables

```yaml
envFrom:
- secretRef:
    name: db-secret
```

### As Individual Environment Variables

```yaml
env:
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: username
```

### Mounted as Files

```yaml
volumes:
- name: secret-vol
  secret:
    secretName: db-secret

volumeMounts:
- name: secret-vol
  mountPath: /etc/secret
  readOnly: true
```

## Encoding vs Encryption

- Base64 encoding ≠ encryption
- Secrets are stored in **etcd**
- Encryption at rest must be explicitly enabled

See: [[kube-apiserver]] encryption configuration.

## Security Considerations

- Avoid committing Secrets to Git
- Use RBAC to restrict access
- Enable encryption at rest
- Rotate Secrets regularly
- Prefer external secret managers when possible

## Observability

List Secrets:

```bash
kubectl get secrets
```

Describe metadata (not values):

```bash
kubectl describe secret db-secret
```

## Secrets vs ConfigMaps

|**Feature**|**Secret**|**ConfigMap**|
|---|---|---|
|Intended for sensitive data|✅|❌|
|Base64 encoded|✅|❌|
|Encrypted at rest|Optional|❌|

## Key Mental Model

A Secret is **not magical protection** — it’s controlled exposure.

Kubernetes hides the data from casual eyes,
but real security comes from **RBAC, encryption, and discipline**.