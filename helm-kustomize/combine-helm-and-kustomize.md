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

### 1. Einfaches Post-Rendering Setup

```bash
# Helm Chart mit Kustomize Post-Rendering installieren
helm create my-chart 
helm install my-app2 ./my-chart --post-renderer ./kustomize-post-renderer.sh
```

### 2. Post-Renderer Script

```bash
#!/bin/bash
# kustomize-post-renderer.sh
cat <&0 > base.yaml
kustomize build
```

### 3. Kustomization.yaml für Post-Rendering

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- base.yaml

patchesStrategicMerge:
- patches/deployment-patch.yaml

images:
- name: nginx
  newTag: "1.21"
```

### 4. Deployment Patch Beispiel

```yaml
# patches/deployment-patch.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: my-app
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
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

## Advanced Use Cases

### 1. Multi-Cluster Deployments

```bash
# Deployment für verschiedene Cluster
helm template my-app ./chart --values values-cluster-a.yaml | \
  kustomize build environments/cluster-a | \
  kubectl apply -f -
```

### 2. GitOps Integration

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: my-app
spec:
  source:
    repoURL: https://github.com/my-org/my-repo
    path: helm-kustomize
    plugin:
      name: helm-kustomize
```

### 3. Secrets Management

```yaml
# kustomization.yaml mit Secret Generator
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
- base.yaml

secretGenerator:
- name: app-secrets
  env: secrets.env
```

## Best Practices

### 1. Versionierung

- Helm Charts für Basis-Templates und Versionierung
- Kustomize für environment-spezifische Anpassungen
- Git Tags für Release-Versionen

### 2. Testing

```bash
# Dry-run für Testing
helm template my-app ./chart --values values-dev.yaml | \
  kustomize build environments/dev | \
  kubectl apply --dry-run=client -f -
```

### 3. Validation

```bash
# Validierung der finalen Manifeste
helm template my-app ./chart | \
  kustomize build | \
  kubeval -
```

## Deployment Scripts




