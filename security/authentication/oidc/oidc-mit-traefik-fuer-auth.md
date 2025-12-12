# Traefik mit Authentifizierung für nachgelagerte Services verwenden mit OIDC 


## 1. OAuth2-Proxy Deployment (wird für die Authentifizierung verwendet)

  * In go geschrieben
  * Besser: Mit helm - Chart ausrollen 

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: oauth2-proxy
  namespace: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oauth2-proxy
  template:
    metadata:
      labels:
        app: oauth2-proxy
    spec:
      containers:
      - name: oauth2-proxy
        image: quay.io/oauth2-proxy/oauth2-proxy:latest
        args:
        - --provider=oidc
        - --oidc-issuer-url=https://keycloak.example.com/realms/myrealm
        - --client-id=traefik
        - --client-secret=your-secret-here
        - --cookie-secret=random-32-byte-string
        - --email-domain=*
        - --upstream=static://200
        - --http-address=0.0.0.0:4180
        - --redirect-url=https://auth.example.com/oauth2/callback
        ports:
        - containerPort: 4180
---
apiVersion: v1
kind: Service
metadata:
  name: oauth2-proxy
  namespace: traefik
spec:
  selector:
    app: oauth2-proxy
  ports:
  - port: 4180
    targetPort: 4180
```

## 2. Traefik Middleware

```yaml
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: oidc-auth
  namespace: default
spec:
  forwardAuth:
    address: http://oauth2-proxy.traefik.svc.cluster.local:4180
    authResponseHeaders:
    - X-Auth-Request-User
    - X-Auth-Request-Email
    - X-Auth-Request-Access-Token
```

## 3. IngressRoute für OAuth2-Proxy selbst

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: oauth2-proxy
  namespace: default
spec:
  entryPoints:
  - websecure
  routes:
  - match: Host(`auth.example.com`)
    kind: Rule
    services:
    - name: oauth2-proxy
      port: 4180
  tls:
    certResolver: letsencrypt
```

## 4. Geschützte App mit Middleware

```yaml
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: protected-app
  namespace: default
spec:
  entryPoints:
  - websecure
  routes:
  - match: Host(`app.example.com`)
    kind: Rule
    middlewares:
    - name: oidc-auth
      namespace: default
    services:
    - name: my-app
      port: 80
  tls:
    certResolver: letsencrypt
```

## Keycloak Client Setup

In Keycloak (oder anderem OIDC Provider):
- **Client ID**: `traefik`
- **Valid Redirect URIs**: `https://auth.example.com/oauth2/callback`
- **Access Type**: confidential
- **Standard Flow**: enabled

**Cookie-Secret generieren:**
```bash
python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
```
