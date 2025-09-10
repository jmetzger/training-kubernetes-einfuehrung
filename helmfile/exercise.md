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

## 1) Projekt anlegen

```bash
cd
mkdir -p helmfile-nginx/values
cd helmfile-nginx
```

**Struktur (Ziel):**

```
helmfile-nginx/
├─ helmfile.yaml
└─ values/
   ├─ common.yaml
   ├─ dev.yaml
   └─ prod.yaml
```

---

## 2) Dateien erstellen

### `helmfile.yaml`

```
nano helmfile.yaml
```

```yaml
# helmfile.yaml
helmDefaults:
# in seconds 
  timeout: 300
  wait: true
  atomic: true
  createNamespace: true

repositories:
  - name: bitnami
    url: https://charts.bitnami.com/bitnami

releases:
  - name: nginx-dev
    namespace: dev-web-<dein-name>
    labels:
      env: dev
    chart: bitnami/nginx
    # version: "~21.0.0"   # optional: für reproduzierbare Deploys pinnen
    values:
      - values/common.yaml
      - values/dev.yaml

  - name: nginx-prod
    namespace: prod-web-<dein-name>
    labels:
      env: prod
    chart: bitnami/nginx
    values:
      - values/common.yaml
      - values/prod.yaml
```

### `values/common.yaml`

```
nano values/common.yaml
```

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

```

### `values/dev.yaml`

```
nano values/dev.yaml
```

```
replicaCount: 1
serverBlock: |-
  server {
    listen 0.0.0.0:8080;
    location / {
      return 200 'Hello from NGINX (env=dev)';
      add_header Content-Type text/plain;
    }
  }

```

### `values/prod.yaml`

```
nano values/prod.yaml
```

```
replicaCount: 2
serverBlock: |-
  server {
    listen 0.0.0.0:8080;
    location / {
      return 200 'Hello from NGINX (env=prod)';
      add_header Content-Type text/plain;
    }
  }
```

> Hiermit setzen wir eine eigene Seite 


## 3) Repository & Dry-Run

```bash
helmfile repos
helmfile -l env=dev template      # rendert Manifeste für dev (Dry-Run ohne Cluster)
helmfile -l env=prod template     # rendert für prod
```

Optional (mit Diff-Plugin):

```bash
helmfile -l env=dev diff
```

## 4) Deploy (dev)

```bash
# Install/Upgrade dev
helmfile -l env=dev apply

# Checks
kubectl -n web-<euer-name> get deploy,po,svc,ingress
```

## 5) Deploy (prod)

```bash
# Install/Upgrade prod
helmfile -l env=prod apply

# Checks
kubectl -n web-<euername> get deploy/nginx-prod
kubectl -n web-<euername> get svc/ingress/nginx-prod
```


