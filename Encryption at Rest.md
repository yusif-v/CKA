# Encryption at Rest
## Overview

**Encryption at Rest** protects sensitive Kubernetes data **while it is stored on disk**, primarily in **etcd**.

Without it, objects like [[Secrets]] are stored in **plain text** inside etcd.

Encryption at rest ensures that even if etcd storage is compromised, the data remains unreadable.

## What Gets Encrypted

Common resources protected by encryption:
- [[Secrets]]
- [[ConfigMap]] data (optional)
- Custom Resources (optional)

You choose **which resources** to encrypt.

## Where Encryption Happens

- Encryption is handled by [[kube-apiserver]]
- Data is encrypted **before** being written to etcd
- Data is decrypted **when read** by authorized clients

etcd itself is unaware of the encryption.

## Encryption Providers

Kubernetes supports multiple encryption providers:
- aescbc (recommended for exams)
- aesgcm
- secretbox
- identity (no encryption, plaintext)
- External KMS providers

## Encryption Configuration File

Encryption is configured via a file passed to kube-apiserver.

Example:

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - aescbc:
      keys:
      - name: key1
        secret: c2VjcmV0LWtleQ==
  - identity: {}
```

- Keys must be **base64-encoded**
- First provider is used for encryption
- Others are used for decryption fallback

## Enabling Encryption

The kube-apiserver must be started with:

```bash
--encryption-provider-config=/etc/kubernetes/encryption-config.yaml
```

This is usually set in the Static Pod manifest:

```bash
/etc/kubernetes/manifests/kube-apiserver.yaml
```

## Key Rotation

- Add a new key **above** the old one
- Restart kube-apiserver
- New writes use the new key
- Old data remains decryptable

To re-encrypt existing data, a rewrite is required.

## Verifying Encryption

Check raw etcd data (advanced):

```bash
ETCDCTL_API=3 etcdctl get /registry/secrets/default/my-secret
```

Encrypted data appears as binary, not plaintext.

## Common Mistakes

- Forgetting to restart kube-apiserver
- Leaving identity as the first provider
- Losing encryption keys (data becomes unrecoverable)
- Assuming Secrets are encrypted by default

## Security Considerations

- Store encryption keys securely
- Backup encryption config
- Restrict access to etcd
- Combine with RBAC and TLS

## Key Mental Model

Encryption at rest is **last-line defense**.

RBAC controls _who_ can ask for data.
Encryption controls _what happens if storage is stolen_.

Kubernetes locks the vault —
but you must keep the keys.