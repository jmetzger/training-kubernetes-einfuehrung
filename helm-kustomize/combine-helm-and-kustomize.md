# Helm und Kustomize kombinieren

## Übersicht

Die Kombination von Helm und Kustomize bietet die Flexibilität von Kustomize mit der Paketierung und Versionierung von Helm. Dies ist besonders nützlich für komplexe Deployments, die environment-spezifische Anpassungen benötigen.

## Helm Post-Rendering mit Kustomize

### Grundlegendes Konzept

Helm kann nach dem Template-Rendering einen Post-Renderer aufrufen. Hier kann Kustomize die gerenderten Manifeste weiter anpassen.

### Workflow

1. Helm rendert Templates basierend auf Values
2. Kustomize modifiziert die gerenderten Manifeste
3. Finale Manifeste werden deployed

## Übung 

### Schritt 1: Arbeitsverzeichnis erstellen

```bash
# Erstelle Arbeitsverzeichnis
cd
mkdir helm-kustomize-demo
cd helm-kustomize-demo
```

### Schritt 2: Helm Chart erstellen

```bash
# Erstelle ein neues Helm Chart
helm create my-chart
```

### Schritt 3: Kustomize-Verzeichnis erstellen

```bash
# Erstelle Kustomize-Verzeichnis
mkdir kustomize
cd kustomize
```

### Schritt 4: Post-Renderer Script erstellen

```bash
# Erstelle das Post-Renderer Script
cat > kustomize-post-renderer.sh << 'EOF'
#!/bin/bash
# Wechsle ins kustomize Verzeichnis
cd "$(dirname "$0")"
# Speichere Helm Output als base.yaml
cat <&0 > base.yaml
# Führe kustomize build aus
kubectl kustomize .
EOF

# Script ausführbar machen
chmod +x kustomize-post-renderer.sh
```

### Schritt 5: Patches-Verzeichnis erstellen

```bash
# Erstelle patches Verzeichnis
mkdir -p patches
```

### Schritt 6: Deployment Patch erstellen

```bash
# Erstelle deployment-patch.yaml
cat > patches/deployment-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app-my-chart
spec:
  template:
    spec:
      containers:
      - name: my-chart
        resources:
          requests:
            memory: "80Mi"
            cpu: "300m"
          limits:
            memory: "80Mi"
            cpu: "300m"
EOF
```

### Schritt 7: Kustomization.yaml erstellen

```bash
# Erstelle kustomization.yaml
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- base.yaml

patches:
- path: patches/deployment-patch.yaml

images:
- name: nginx
  newTag: "1.21"
EOF
```

### Schritt 8: Zurück ins Hauptverzeichnis

```bash
# Gehe zurück ins Hauptverzeichnis
cd ..
```

### Schritt 9: Verzeichnisstruktur prüfen

```bash
# Prüfe die Verzeichnisstruktur
tree .
# Ergebnis sollte sein:
# .
# ├── kustomize/
# │   ├── kustomization.yaml
# │   ├── kustomize-post-renderer.sh
# │   └── patches/
# │       └── deployment-patch.yaml
# └── my-chart/
#     ├── Chart.yaml
#     ├── charts/
#     ├── templates/
#     └── values.yaml
```

### Schritt 10: Deployment testen

```bash
# Teste das Setup mit dry-run
helm upgrade --install -n my-kapp-<namenskuerzel> my-app ./my-chart --post-renderer ./kustomize/kustomize-post-renderer.sh --dry-run --debug --create-namespace 
```

### Schritt 11: Deployment ausführen

```bash
# Führe das Deployment aus
helm upgrade --install -n my-kapp-<namenskuerzel> my-app ./my-chart --post-renderer ./kustomize/kustomize-post-renderer.sh --create-namespace

helm -n my-kapp-<namenskuerzel> list 
helm -n my-kapp-<namenskuerzel> get manifest my-app
```

### Schritt 12: Deployment prüfen

```bash
# Prüfe das Deployment
kubectl -n my-kapp-<namenskuerzel> get pods
kubectl -n my-kapp-<namenskuerzel> describe deployment my-app-my-chart
```

## Environment-spezifische Anpassungen

### Ordnerstruktur

```
helm-kustomize/
├── chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── environments/
│   ├── dev/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── patches/
│   └── prod/
│       ├── kustomization.yaml
│       └── patches/
└── scripts/
    └── deploy.sh
```

### Development Environment

```yaml
# environments/dev/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base.yaml

patchesStrategicMerge:
- patches/dev-resources.yaml

replicas:
- name: my-app
  count: 1

commonLabels:
  environment: dev
```

### Production Environment

```yaml
# environments/prod/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- ../../base.yaml

patchesStrategicMerge:
- patches/prod-resources.yaml
- patches/prod-security.yaml

replicas:
- name: my-app
  count: 3

commonLabels:
  environment: prod
```


## Best Practices


### 2. Testing

```bash
# Dry-run für Testing
helm template my-app ./chart --values values-dev.yaml | \
  kustomize build environments/dev | \
  kubectl apply --dry-run=client -f -
```





