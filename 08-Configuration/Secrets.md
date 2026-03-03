---
tags: [cka/architecture, configuration, security]
aliases: [Secret, kubernetes secret, sensitive config]
---

# Secrets

> **Exam Domain**: Cluster Architecture, Installation & Configuration (25%)
> **Related**: [[ConfigMap]], [[Pods]], [[RBAC]], [[TLS in Kubernetes]], [[Environment Variables]]

## Overview

A **Secret** is a Kubernetes object for storing **sensitive data** — passwords, tokens, certificates, and keys. Secrets are similar to [[ConfigMap]]s but designed for confidential information. They are base64-encoded (not encrypted by default), stored in [[etcd]], and accessed only by Pods that explicitly reference them.

> [!warning]
> Base64 encoding is **not** encryption. Secrets require RBAC restrictions, etcd encryption-at-rest, and access auditing to be truly secure.

## Secret Types

| Type | Use Case |
|---|---|
| `Opaque` | Generic key-value (default) |
| `kubernetes.io/tls` | TLS certificates |
| `kubernetes.io/dockerconfigjson` | Image pull credentials |
| `kubernetes.io/service-account-token` | Service account tokens |

## Creating Secrets

### Imperatively

```bash
# Generic (Opaque) secret
kubectl create secret generic db-secret \
  --from-literal=username=admin \
  --from-literal=password=S3cur3P@ss

# From files
kubectl create secret generic db-secret --from-file=credentials.txt

# TLS secret
kubectl create secret tls my-tls \
  --cert=server.crt \
  --key=server.key

# Docker registry secret
kubectl create secret docker-registry regcred \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword
```

### Declaratively (values must be base64-encoded)

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
data:
  username: YWRtaW4=        # echo -n 'admin' | base64
  password: UzNjdXIzUEBzcw== # echo -n 'S3cur3P@ss' | base64
```

Encode/decode manually:

```bash
echo -n 'admin' | base64          # Encode
echo -n 'YWRtaW4=' | base64 -d   # Decode
```

## Using Secrets in Pods

### As Environment Variables (all keys)

```yaml
spec:
  containers:
  - name: app
    envFrom:
    - secretRef:
        name: db-secret
```

### As Individual Environment Variables

```yaml
spec:
  containers:
  - name: app
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
```

### Mounted as Files (recommended for sensitive data)

```yaml
spec:
  volumes:
  - name: secret-vol
    secret:
      secretName: db-secret
      defaultMode: 0400   # Read-only for owner
  containers:
  - name: app
    volumeMounts:
    - name: secret-vol
      mountPath: /etc/secrets
      readOnly: true
```

### Image Pull Secrets

```yaml
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: app
    image: registry.example.com/myapp:latest
```

## Secrets vs ConfigMaps

| Feature | Secret | ConfigMap |
|---|---|---|
| Intended for sensitive data | ✅ | ❌ |
| Base64 encoded in etcd | ✅ | ❌ |
| Encrypted at rest (optional) | ✅ configurable | ❌ |
| Size limit | 1MB | 1MB |

## Security Best Practices

- Restrict access with [[RBAC]] — only grant `get`/`list` on Secrets to pods that need them
- Enable **encryption at rest** in kube-apiserver (`--encryption-provider-config`)
- Never commit Secrets to Git — use external secret managers (Vault, AWS Secrets Manager)
- Rotate Secrets regularly
- Use `readOnly: true` for volume mounts
- Audit Secret access via kube-apiserver audit logs

## Key Commands

```bash
# List secrets
kubectl get secrets

# Describe metadata (NOT values)
kubectl describe secret db-secret

# View encoded values
kubectl get secret db-secret -o yaml

# Decode a value inline
kubectl get secret db-secret -o jsonpath='{.data.password}' | base64 -d

# Delete secret
kubectl delete secret db-secret
```

## Common Issues / Troubleshooting

- **ImagePullBackOff** → missing or wrong `imagePullSecrets`; check registry credentials
- **`CreateContainerConfigError`** → referenced Secret doesn't exist; create it first
- **Secret value looks garbled** → it's base64-encoded; decode with `base64 -d`
- **RBAC blocking access** → service account lacks permission to read the Secret
- **Wrong namespace** → Secrets are namespace-scoped; must be in same namespace as Pod

## Related Notes

- [[ConfigMap]] — For non-sensitive configuration
- [[RBAC]] — Controls who can read/list Secrets
- [[TLS in Kubernetes]] — TLS Secrets store cluster certificates
- [[Environment Variables]] — How Secret data surfaces in containers

## Key Mental Model

A Secret is **not magical protection** — it is **controlled exposure**. Kubernetes hides the data from casual eyes, but real security comes from [[RBAC]], encryption at rest, and operational discipline. The lock is only as strong as who holds the keys.
