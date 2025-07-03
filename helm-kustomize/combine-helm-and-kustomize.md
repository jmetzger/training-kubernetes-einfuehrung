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

### Schritt 1: Helm Chart erstellen

```bash
# Erstelle ein neues Helm Chart
helm create my-chart
cd my-chart
```

### Schritt 2: Post-Renderer Script erstellen

```bash
# Erstelle das Post-Renderer Script
cat > kustomize-post-renderer.sh << 'EOF'
#!/bin/bash
cat <&0 > base.yaml
kustomize build
EOF

# Script ausführbar machen
chmod +x kustomize-post-renderer.sh
```

### Schritt 3: Patches-Verzeichnis erstellen

```bash
# Erstelle patches Verzeichnis
mkdir -p patches
```

### Schritt 4: Deployment Patch erstellen

```bash
# Erstelle deployment-patch.yaml
cat > patches/deployment-patch.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-chart
spec:
  template:
    spec:
      containers:
      - name: my-chart
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
EOF
```

### Schritt 5: Kustomization.yaml erstellen

```bash
# Erstelle kustomization.yaml
cat > kustomization.yaml << 'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- base.yaml

patchesStrategicMerge:
- patches/deployment-patch.yaml

images:
- name: nginx
  newTag: "1.21"
EOF
```

### Schritt 6: Deployment testen

```bash
# Teste das Setup mit dry-run
helm install my-app ./my-chart --post-renderer ./kustomize-post-renderer.sh --dry-run --debug
```

### Schritt 7: Deployment ausführen

```bash
# Führe das Deployment aus
helm install my-app ./my-chart --post-renderer ./kustomize-post-renderer.sh
```

### Schritt 8: Deployment prüfen

```bash
# Prüfe das Deployment
kubectl get pods
kubectl describe deployment my-app-my-chart
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





