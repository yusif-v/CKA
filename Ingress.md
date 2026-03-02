# Ingress
## Overview

**Ingress** is a Kubernetes resource that manages external HTTP/HTTPS access to Services inside the cluster.

It acts as a smart entry point that can:
- Route traffic to different Services
- Provide load balancing
- Handle SSL/TLS termination
- Enable name-based virtual hosting
    

  

Ingress = _Layer 7 (HTTP/HTTPS) Traffic Router_

---

## **Why Ingress Exists**

  

Without Ingress:

1. Each Service must be exposed using a LoadBalancer or NodePort.
    
2. This creates multiple external IPs.
    
3. Managing routing, TLS, and domains becomes difficult.
    

  

Ingress allows exposing **multiple Services using a single external IP** with centralized routing rules.

---

## **How Ingress Works**

  

Workflow:

```
Client → Ingress Controller → Ingress Rules →
Matches Host/Path → Routes to Service → Pod
```

Important:

Ingress itself is just a configuration object.

The actual traffic handling is done by an **Ingress Controller**.

---

## **Ingress Components**

|**Component**|**Purpose**|
|---|---|
|Ingress Resource|Defines routing rules|
|Ingress Controller|Implements those rules|
|Service|Backend receiving traffic|
|TLS Secret|Stores SSL certificates|

---

## **Example Ingress Resource**

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress

spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

This routes:

Traffic to myapp.example.com → web-service.

---

## **Path-Based Routing**

  

Ingress can route based on URL paths:

```
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 80

      - path: /web
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

Requests are routed depending on the path.

---

## **Host-Based Routing**

  

Multiple domains can point to different Services:

```
spec:
  rules:
  - host: shop.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shop-service
            port:
              number: 80

  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
```

---

## **TLS Configuration (HTTPS)**

  

Ingress can terminate SSL using a Secret:

```
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: my-tls-secret
```

Create the TLS Secret:

```
kubectl create secret tls my-tls-secret \
  --cert=cert.crt \
  --key=key.key
```

Ingress now handles HTTPS encryption.

---

## **Ingress Controller**

  

Ingress will not work unless a controller is installed.

  

Common controllers:

- NGINX Ingress Controller
    
- HAProxy
    
- Traefik
    
- Cloud provider controllers
    

  

The controller:

- Watches Ingress resources
    
- Configures reverse proxy
    
- Routes traffic accordingly
    

---

## **Useful Commands**

```
kubectl get ingress
kubectl describe ingress <name>

kubectl get pods -n ingress-nginx
kubectl logs <controller-pod>
```

---

## **Ingress vs Service Type LoadBalancer**

|**Feature**|**Ingress**|**LoadBalancer Service**|
|---|---|---|
|Layer|L7 (HTTP/HTTPS)|L4 (TCP/UDP)|
|Routing|Host/Path based|No routing|
|TLS Termination|Yes|Manual|
|IP Usage|Single IP for many apps|One IP per Service|
|Flexibility|High|Limited|

Ingress is more efficient for exposing web applications.

---

## **Important Behavior**

  

Ingress does not expose anything by itself.

  

It only defines routing rules.

The Ingress Controller reads those rules and configures the actual proxy.

  

No controller = Ingress does nothing.

---

## **Summary**

  

Ingress provides centralized Layer 7 routing for Kubernetes Services, allowing multiple applications to be exposed through a single entry point with support for domain-based routing, path-based routing, and TLS termination.