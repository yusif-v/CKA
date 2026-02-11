Here is a **clean, standalone Obsidian note for [[Authentication]]**, aligned with your Kubernetes / CKA notes style and using fenced commands.

---

# **Authentication**

  

## **Overview**

  

**Authentication** in Kubernetes is the process of **verifying the identity of a user or component** before granting access.

  

Kubernetes itself **does not store user accounts** — it relies on certificates, tokens, and external identity providers.

  

🔗 Related:

- [[TLS in Kubernetes]]
    
- [[Kubeconfig]]
    

---

## **Supported Authentication Methods**

  

### **1. Client Certificates**

- X.509 certificates identify users or components
    
- Common in kubeadm clusters for control plane components and admin users
    

  

Example kubeconfig entry:

```
users:
- name: admin
  user:
    client-certificate: /etc/kubernetes/pki/admin.crt
    client-key: /etc/kubernetes/pki/admin.key
```

---

### **2. Bearer Tokens**

- Tokens passed in HTTP header: Authorization: Bearer <token>
    
- Used for service accounts
    
- Static or JWT tokens
    

  

Get service account token:

```
kubectl get secret <sa-name> -o jsonpath='{.data.token}' | base64 --decode
```

---

### **3. Static Password Files (Basic Auth) – Deprecated**

- Uses --basic-auth-file for simple username/password
    
- Not recommended for production
    

---

### **4. OpenID Connect / OIDC**

- Integrates with external identity providers (Google, Azure AD, etc.)
    
- Tokens exchanged for Kubernetes credentials
    
- Configured via kube-apiserver flags:
    

```
--oidc-issuer-url
--oidc-client-id
--oidc-username-claim
```

---

### **5. Webhooks**

- External HTTP service verifies identity
    
- Kubernetes sends bearer token to webhook
    
- Webhook returns success/failure
    

  

Configured via:

```
--authentication-token-webhook-config-file=<file>
```

---

## **Service Account Authentication**

- Each Pod can use a **service account token**
    
- Automatically mounted at:
    

```
/var/run/secrets/kubernetes.io/serviceaccount/token
```

- Used for in-cluster API access
    

  

Check default service accounts:

```
kubectl get serviceaccounts
```

---

## **Authentication Flow**

1. User/Component sends a request to **kube-apiserver**
    
2. API server checks **credentials** (certificate, token, etc.)
    
3. On success → identifies user and passes to **Authorization**
    

  

🔗 Related:

- [[Authorization]]
    

---

## **Debugging Authentication**

  

Check logs for:

```
"authentication failed"
```

Test with kubectl:

```
kubectl auth can-i get pods --as <user>
```

---

## **Best Practices**

- Use **client certificates** for components
    
- Use **service accounts** for in-cluster apps
    
- Integrate **OIDC** for human users
    
- Avoid static passwords
    
- Rotate tokens and certificates regularly
    

---

## **Key Mental Model**

  

Authentication is **“who are you?”** in Kubernetes:

- Certificates = ID card
    
- Tokens = badge
    
- OIDC = passport checked by trusted authority
    

  

Only after identity is confirmed does Kubernetes check **what you’re allowed to do** (authorization).