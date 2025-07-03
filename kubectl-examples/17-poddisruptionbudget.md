# PodDisruptionBudget (PDB) - Übung

## Was ist ein PodDisruptionBudget?

Ein PodDisruptionBudget (PDB) ist ein Kubernetes-Objekt, das die Verfügbarkeit von Pods während geplanter Wartungsarbeiten schützt. Es definiert, wie viele Pods einer Anwendung mindestens verfügbar bleiben müssen oder höchstens gleichzeitig gestört werden dürfen.

## Wann brauche ich ein PodDisruptionBudget unbedingt?

- **Hochverfügbare Anwendungen**: Bei kritischen Services, die kontinuierlich erreichbar sein müssen
- **Cluster-Wartung**: Wenn Nodes regelmäßig für Updates oder Wartung runtergenommen werden

## Wann ist ein PodDisruptionBudget nicht nötig?

- **Einzelne Pods**: Bei Anwendungen mit nur einem Pod (PDB würde Updates blockieren)
- **Unkritische Services**: Bei Test- oder Entwicklungsumgebungen
- **Batch-Jobs**: Bei einmaligen Tasks ohne Verfügbarkeitsanforderungen
- **Stateless Services ohne SLA**: Bei Services ohne Verfügbarkeitsgarantien

## Praktische Übung

### Schritt 1: Deployment ohne PDB erstellen

```bash
# Deployment-Manifest erstellen
mkdir -p manifests
cd manifests
mkdir pdb
cd pdb 
nano deployment-nginx.yaml
```

```yaml
# deployment-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-app
  labels:
    app: nginx-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-app
  template:
    metadata:
      labels:
        app: nginx-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

```bash
# Service-Manifest erstellen
nano service-nginx.yaml
```

```yaml
# service-nginx.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-app
spec:
  selector:
    app: nginx-app
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

```bash
# Manifeste anwenden
kubectl apply -f .

# Status überprüfen
kubectl get pods -l app=nginx-app
```

### Schritt 2: Test ohne PDB - Drain simulieren

```bash
# Alle Pods auflisten mit Node-Zuordnung
kubectl get pods -o wide -l app=nginx-app

# Einen Node identifizieren und "draining" simulieren
NODE_NAME=$(kubectl get pods -l app=nginx-app -o jsonpath='{.items[0].spec.nodeName}')
echo "Simuliere Drain auf Node: $NODE_NAME"

# Pods von diesem Node löschen (simuliert Drain)
kubectl delete pods -l app=nginx-app --field-selector spec.nodeName=$NODE_NAME
```

### Schritt 3: PodDisruptionBudget erstellen

```bash
# PDB-Manifest erstellen
nano pdb-nginx.yaml
```

```yaml
# pdb-nginx.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: nginx-app
```

```bash
# PDB anwenden
kubectl apply -f pdb-nginx.yaml

# PDB Status überprüfen
kubectl get pdb nginx-pdb
kubectl describe pdb nginx-pdb
```

### Schritt 4: PDB testen mit kubectl drain

```bash
# Verfügbare Nodes anzeigen
kubectl get nodes

# Einen Node zum Draining auswählen
NODE_NAME=$(kubectl get nodes -o jsonpath='{.items[1].metadata.name}')

# Node draining mit PDB - beobachten Sie die Ausgabe
kubectl drain $NODE_NAME --ignore-daemonsets --delete-emptydir-data

# PDB Status während des Drains überprüfen
kubectl get pdb nginx-pdb
kubectl get pods -l app=nginx-app
```

### Schritt 5: PDB mit maxUnavailable

```bash
# PDB mit maxUnavailable erstellen
nano pdb-max-unavailable.yaml
```

```yaml
# pdb-max-unavailable.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: nginx-pdb-max
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx-app
```

```bash
kubectl apply -f pdb-max-unavailable.yaml
kubectl get pdb nginx-pdb-max
```

### Schritt 6: Cleanup der ersten Übung

```bash
# Alle erstellten Ressourcen löschen
kubectl delete -f deployment-nginx.yaml
kubectl delete -f service-nginx.yaml
kubectl delete -f pdb-max-unavailable.yaml

# Node wieder aktivieren (falls gedrained)
kubectl uncordon $NODE_NAME
```

## Übung 2: PDB verhindert Deployment-Start

### Schritt 1: Problematisches Szenario erstellen

```bash
# Deployment mit zu wenig Replikas erstellen
nano deployment-insufficient.yaml
```

```yaml
# deployment-insufficient.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
```

```bash
# PDB mit zu hohen Anforderungen erstellen
nano pdb-too-strict.yaml
```

```yaml
# pdb-too-strict.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
spec:
  minAvailable: 3
  selector:
    matchLabels:
      app: web-app
```

### Schritt 2: Problem demonstrieren

```bash
# Zuerst das PDB erstellen
kubectl apply -f pdb-too-strict.yaml

# PDB Status überprüfen
kubectl get pdb web-app-pdb
kubectl describe pdb web-app-pdb

# Dann das Deployment erstellen
kubectl apply -f deployment-insufficient.yaml

# Status überprüfen
kubectl get pods -l app=web-app
kubectl get pdb web-app-pdb
```

### Schritt 3: Problem analysieren

```bash
# Detaillierte Analyse des PDB
kubectl describe pdb web-app-pdb

# Events überprüfen
kubectl get events --sort-by=.metadata.creationTimestamp

# Versuche ein Rolling Update (wird blockiert)
kubectl patch deployment web-app -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","image":"nginx:1.21"}]}}}}'

# Status des Rolling Updates überprüfen
kubectl rollout status deployment web-app --timeout=30s
kubectl get rs -l app=web-app
```

### Schritt 4: Problem beheben

```bash
# Option 1: Replicas erhöhen
kubectl scale deployment web-app --replicas=4

# Status überprüfen
kubectl get pods -l app=web-app
kubectl get pdb web-app-pdb

# Option 2: PDB anpassen
nano pdb-fixed.yaml
```

```yaml
# pdb-fixed.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb-fixed
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: web-app
```

```bash
# Altes PDB löschen und neues anwenden
kubectl delete pdb web-app-pdb
kubectl apply -f pdb-fixed.yaml

# Rolling Update nun erfolgreich
kubectl rollout restart deployment web-app
kubectl rollout status deployment web-app
```

### Schritt 5: Cleanup der zweiten Übung

```bash
# Alle Ressourcen löschen
kubectl delete -f deployment-insufficient.yaml
kubectl delete -f pdb-fixed.yaml

# Manifest-Dateien löschen (optional)
rm deployment-insufficient.yaml pdb-too-strict.yaml pdb-fixed.yaml
```

## Best Practices

1. **Verwenden Sie minAvailable** für kritische Services mit fester Mindestanzahl
2. **Verwenden Sie maxUnavailable** für flexiblere Szenarien
3. **Prozentangaben** sind nützlich bei variablen Replikaanzahlen
4. **Testen Sie PDBs** vor der Produktionseinführung
5. **Koordinieren Sie** PDBs mit HPA-Einstellungen
6. **Vermeiden Sie zu strenge PDBs** die Rolling Updates blockieren können
7. **Stellen Sie sicher**, dass minAvailable <= Anzahl der Replikas ist
