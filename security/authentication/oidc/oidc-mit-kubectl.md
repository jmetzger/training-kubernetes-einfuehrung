# Authentifizierung mit oidc für kuectl 

## Voraussetzung (allgemein) 

  * IDP-Provider muss vorhanden sein


## Einrichtung auf dem Kubernetes Server (so -> seit 1.30 (GA 1.32)) 

### Auf dem Server-Host (Control Plane)



```
# Erstellen als
# /etc/kubernetes/auth-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AuthenticationConfiguration
jwt:
- issuer:
    url: https://provider1.example.com
    audiences:
    - kubernetes
  claimMappings:
    username:
      claim: email
    groups:
      claim: groups
  
- issuer:
    url: https://provider2.example.com
    audiences:
    - k8s-prod
  claimMappings:
    username:
      claim: sub
    groups:
      claim: roles
```
```
# API - Flag setzen
# Diese Datei liegt bereits vor und muss angepasst werden
# Static Pod 
# /etc/kubernetes/manifests/kube-apiserver.yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --authentication-config=/etc/kubernetes/auth-config.yaml
    volumeMounts:
    - name: auth-config
      mountPath: /etc/kubernetes/auth-config.yaml
      readOnly: true
  volumes:
  - name: auth-config
    hostPath:
      path: /etc/kubernetes/auth-config.yaml
```

  * Es handelt sich im einen static - pod, wenn die Datei geändert wurde wird der Pod automatisch neu erstellt 



## Voraussetzung (Client-Seite)

  * krew (Plugin Manager für kubectl muss installiert sein)

```
# Linux/macOS
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# PATH erweitern
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
```

## Aufsetzen auf dem Client 

```
# OIDC-Plugin installieren (falls noch nicht vorhanden)
kubectl krew install oidc-login
# Kubeconfig anpassen
kubectl config set-credentials oidc-user \
  --exec-api-version=client.authentication.k8s.io/v1 \
  --exec-command=kubectl \
  --exec-arg=oidc-login \
  --exec-arg=get-token \
  --exec-arg=--oidc-issuer-url=https://dein-idp.example.com \
  --exec-arg=--oidc-client-id=kubernetes \
  --exec-arg=--oidc-client-secret=SECRET
```

```
# Das führt zu folgender kubeconfig
users:
- name: oidc-user
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1
      command: kubectl
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url=https://keycloak.example.com/realms/myrealm
      - --oidc-client-id=kubernetes
      - --oidc-client-secret=SECRET  # optional
```

```
# neuen context erstellen
# Cluster-Eintrag muss vorhanden sein
kubectl config set-context oidc-context \
  --cluster=dein-cluster \
  --user=oidc-user

# Context verwenden 
kubectl config use-context oidc-context
```

```
# jetzt kannst du ganz normal Befehle verwenden
# z. B.
kubectl get pods
```

## Wie funktioniert das ganze ? 

```
kubectl get pods
```

### 2. kubectl prüft Kubeconfig
- Findet OIDC-Config (exec-Plugin: `kubectl oidc-login`)
- **Kein Token vorhanden** → startet Auth-Flow

### 3. Browser-Login
- Plugin öffnet Browser automatisch
- Du loggst dich bei deinem OIDC-Provider ein (z.B. Keycloak, Google)
- Provider gibt **ID-Token** (JWT) zurück
- Token wird **lokal gecacht** (~/.kube/cache/oidc-login/)

### 4. kubectl → API-Server
```
Authorization: Bearer eyJhbGc...  (JWT-Token)
```

## Wie ist ein jwt aufgebaut ?

```
3 Teile
1. Header
2. Payload
3. Signature
```

## Wie sieht der Payload aus ? 

```
{
  "iss": "https://provider1.example.com",
  "aud": "kubernetes",
  "email": "jochen@example.com",
  "groups": ["admins", "developers"]
}
```
