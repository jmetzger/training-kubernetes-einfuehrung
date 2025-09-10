# Übung: NGINX mit Helmfile verwalten (dev & prod)

## 0) Voraussetzungen

* kubectl & Helm v3
* helmfile installiert (`helmfile version`)
* Kubernetes‐Namespace `web` (wird unten automatisch angelegt)
* Optional: Helm Diff Plugin (nur für `helmfile diff` nötig)

## Step 0.5) Helm Diff installieren 


```bash
# Optional: Helm Diff Plugin
helm plugin install https://github.com/databus23/helm-diff
```

---

## 1) Projekt anlegen

```bash
cd
mkdir -p helmfile-nginx/{environments,values}
cd helmfile-nginx
```

**Struktur (Ziel):**

```
helmfile-nginx/
├─ helmfile.yaml
├─ environments/
│  ├─ dev.yaml
│  └─ prod.yaml
└─ values/
   ├─ common.yaml
   ├─ dev.yaml
   └─ prod.yaml
```

---

## 2) Dateien erstellen

### `helmfile.yaml`

```yaml
# helmfile.yaml
helmDefaults:
  timeout: 5m
  wait: true
  atomic: true
  createNamespace: true
  namespace: web

repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

environments:
  dev:
    values:
      - environments/dev.yaml
  prod:
    values:
      - environments/prod.yaml

releases:
  - name: nginx-{{ .Environment.Name }}
    namespace: web-<euernamenskuerzel>
    chart: bitnami/nginx
    # Tipp: Version pinnen, z.B. "~18.0.0" – hier unpinned für die Übung
    version: ""
    values:
      - values/common.yaml
      - values/{{ .Environment.Name }}.yaml
    installed: true
```

### `environments/dev.yaml`

```yaml
# environments/dev.yaml
environmentName: dev
ingressHost: dev.local
serviceType: ClusterIP
replicas: 1
```

### `environments/prod.yaml`

```yaml
# environments/prod.yaml
environmentName: prod
ingressHost: www.example.com   # anpassen
serviceType: ClusterIP         # ggf. LoadBalancer, wenn verfügbar
replicas: 2
```

### `values/common.yaml`

```yaml
# values/common.yaml (wird für dev & prod geladen)
image:
  debug: false

service:
  # Wird per env überschrieben (serviceType)
  type: ClusterIP
  ports:
    http: 80

# Einfache Index-Seite aktivieren
serverBlock: |-
  server {
    listen 0.0.0.0:8080;
    location / {
      return 200 'Hello from NGINX via Helmfile (env={{ .Environment.Name }})';
      add_header Content-Type text/plain;
    }
  }
containerPorts:
  http: 8080

ingress:
  enabled: true
  ingressClassName: ""
  hostname: ""    # wird per env gesetzt
  path: /
  pathType: Prefix
  annotations: {}
```

### `values/dev.yaml`

```yaml
# values/dev.yaml
replicaCount: {{ .Environment.Values.replicas }}

service:
  type: {{ .Environment.Values.serviceType }}

ingress:
  hostname: {{ .Environment.Values.ingressHost }}
```

### `values/prod.yaml`

```yaml
# values/prod.yaml
replicaCount: {{ .Environment.Values.replicas }}

service:
  type: {{ .Environment.Values.serviceType }}

ingress:
  hostname: {{ .Environment.Values.ingressHost }}
```

> Hinweis: Wir nutzen in `values/*.yaml` Go-Templates von Helmfile (`{{ .Environment.Values.* }}`), um je Environment sauber zu parametrisieren.

---

## 3) Repository & Dry-Run

```bash
helmfile repos
helmfile -e dev template      # rendert Manifeste für dev (Dry-Run ohne Cluster)
helmfile -e prod template     # rendert für prod
```

Optional (mit Diff-Plugin):

```bash
helmfile -e dev diff
```

## 4) Deploy (dev)

```bash
# Install/Upgrade dev
helmfile -e dev apply

# Checks
kubectl -n web-<euer-name> get deploy,po,svc,ingress
```

## 5) Deploy (prod)

```bash
# Install/Upgrade prod
helmfile -e prod apply

# Checks
kubectl -n web-<euername> get deploy/nginx-prod
kubectl -n web get-<euername> svc/ingress/nginx-prod
```


