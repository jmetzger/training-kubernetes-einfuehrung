# Session Stickyness with Nginx 

Yes, **session stickiness (affinity)** via **cookie-based stickiness** **does work** with the **open-source NGINX Ingress Controller**.

Here’s what you need to know to get it working:

---

### ✅ How to Enable Sticky Sessions with Open Source NGINX Ingress

The open-source NGINX Ingress Controller supports sticky sessions using **annotations** and **cookies**.

#### Example Ingress YAML:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-app-ingress
  annotations:
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-hash: "sha1"
spec:
  ingressClassName: nginx
  rules:
    - host: myapp.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-app-service
                port:
                  number: 80
```

---

### 🧠 Explanation of the Annotations

- `nginx.ingress.kubernetes.io/affinity: "cookie"`  
  → Enables cookie-based affinity.

- `nginx.ingress.kubernetes.io/session-cookie-name: "route"`  
  → Names the session cookie (optional, default is `INGRESSCOOKIE`).

- `nginx.ingress.kubernetes.io/session-cookie-hash: "sha1"`  
  → Defines how the cookie value is hashed. Can be `md5`, `sha1`, `index`, etc.

You can also optionally define:
```yaml
nginx.ingress.kubernetes.io/session-cookie-path: "/"
nginx.ingress.kubernetes.io/session-cookie-expires: "172800"   # in seconds
nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
```

---

### 🔍 Important Notes

- This works **only with the open-source NGINX ingress controller**.  
  (The annotations won’t apply to controllers like Traefik, HAProxy, or cloud-specific ones like AWS ALB.)

- You must ensure that **all replicas of the app can handle the traffic** if they receive the same cookie.

- This stickiness is **not persistent across restarts** unless the session cookie is preserved client-side (and the pod labels/service don't change unpredictably).

---

### 💡 Bonus Tip: Enable Ingress Logging (Optional but Useful)
To troubleshoot or verify stickiness:
```yaml
controller:
  config:
    enable-access-log: "true"
    log-format-upstream: "$request_id $remote_addr to $upstream_addr via $cookie_route"
```

---

Want a ready-made Helm values file or `kubectl` manifest for this?
## 🧭 Flow Overview: Cookie-Based Stickiness in NGINX Ingress

```
[Client Browser] 
     ⇅
[NGINX Ingress Controller (Ingress Pod)]
     ⇅
[Kubernetes Service (ClusterIP)]
     ⇅
[App Pod A / B / C (Behind the Service)]
```

---

## 🔁 What Actually Happens (Step-by-Step)

### 1. **Client makes a request**
- Let's say the client hits `myapp.example.com`.

### 2. **Ingress Controller (NGINX) receives the request**
- NGINX is exposed via a LoadBalancer, NodePort, or IngressClass.
- It parses the Ingress resource and applies sticky session rules based on annotations.

### 3. **First Request: No Cookie**
- No session cookie is present, so:
  - NGINX picks a backend pod **randomly** via the Kubernetes `Service`.
  - It sets a sticky cookie on the response, e.g.:
    ```
    Set-Cookie: route=backend1; Path=/; HttpOnly
    ```

### 4. **Subsequent Requests: Cookie Present**
- On later requests, the client sends back:
  ```
  Cookie: route=backend1
  ```
- NGINX uses this cookie value to route to the **same backend pod**.

---

## 🔎 So Where Does the Kubernetes `Service` Come In?

The Kubernetes `Service` is used **internally by NGINX** to **proxy requests to pods**.

### NGINX configuration looks like this (simplified):

```nginx
upstream myapp-service {
    sticky cookie route;
    server 10.0.1.2:8080;  # Pod A
    server 10.0.1.3:8080;  # Pod B
}
```

- These IPs are discovered **via the Kubernetes Service** using Endpoints or EndpointSlices.
- NGINX tracks these pods and their IPs automatically (via a sync controller loop).

---

## ✅ Who Makes Routing Decisions?

- 🔸 **NGINX Ingress Controller** makes the routing decision **based on the cookie value**, not Kubernetes.
- 🔹 Kubernetes `Service` is just a **source of backend pod IPs**, not the router in this case.

---

