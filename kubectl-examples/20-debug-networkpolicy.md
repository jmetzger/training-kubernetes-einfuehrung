# Debugging: NetworkPolicy mit kubectl debug

## Hintergrund

In produktiven Umgebungen laufen Container oft als minimale Images ohne Debug-Tools
(curl, wget, nc). `kubectl debug` schleust einen ephemeral Container mit Debug-Tools
in einen laufenden Pod ein — ohne den Pod neu starten zu muessen.

Ein **Timeout** beim Verbindungsversuch ist ein typisches Zeichen fuer eine blockierende
NetworkPolicy:

| Fehlerbild | Ursache | Diagnose-Befehl |
|-----------|---------|-----------------|
| `Connection timed out` | NetworkPolicy blockiert den Traffic | `kubectl describe networkpolicy` |

---

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 20-debug-networkpolicy
cd 20-debug-networkpolicy
```

Namespace anlegen:

```
kubectl create namespace debug-<dein-name>
```

---

## Schritt 2: Backend Deployment und Service anlegen

```
# vi 01-backend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: nginx:alpine
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
```

```
kubectl apply -f . -n debug-<dein-name>
```

---

## Schritt 3: Frontend Deployment und Service anlegen

Das Frontend laeuft als minimales Python-Image (kein curl, wget, nc).

```
# vi 02-frontend.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: python:3.12-slim
        command: ["python", "-m", "http.server", "8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-svc
spec:
  selector:
    app: frontend
  ports:
  - port: 8080
    targetPort: 8080
```

```
kubectl apply -f . -n debug-<dein-name>
kubectl get pods -n debug-<dein-name>
```

Warten bis beide Pods laufen:

```
kubectl wait deployment frontend backend \
  --for=condition=Available -n debug-<dein-name> --timeout=60s
```

---

## Schritt 4: Baseline — Verbindung funktioniert

Tools im Frontend-Pod pruefen — kein curl, wget, nc vorhanden:

```
FE_POD=$(kubectl get pod -n debug-<dein-name> -l app=frontend -o jsonpath='{.items[0].metadata.name}')
echo $FE_POD
```

```
kubectl exec -it $FE_POD -n debug-<dein-name> -- sh -c 'which curl; which wget; which nc'
```

**Erwartete Ausgabe:**
```
no curl
no wget
no nc
```

Mit `kubectl debug` einen busybox-Container einschleusen und Verbindung testen:

```
kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

Im Debug-Container:

```
wget -qO- http://backend-svc --timeout=5
exit
```

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` — Verbindung funktioniert.

---

## Problem 1: NetworkPolicy blockiert FE zu Backend

## Schritt 5: NetworkPolicy fuer Backend anwenden

```
# vi 03-networkpolicy-backend.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: api-consumer
    ports:
    - protocol: TCP
      port: 80
```

```
kubectl apply -f . -n debug-<dein-name>
```

## Schritt 6: Verbindung testen — Timeout

```
kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

```
wget -qO- http://backend-svc --timeout=5
exit
```

**Erwarteter Fehler:**
```
wget: download timed out
```

Timeout statt `Connection refused` — Endpoints existieren, die NetworkPolicy blockiert.

## Schritt 7: Diagnose — NetworkPolicy und Labels pruefen

```
kubectl describe networkpolicy backend-policy -n debug-<dein-name>
kubectl get pods -n debug-<dein-name> --show-labels
```

**Diagnose:** NetworkPolicy erlaubt nur `role=api-consumer`. Frontend-Pod hat dieses
Label nicht.

## Schritt 8: Fix — Label zum Frontend Deployment hinzufuegen

```
kubectl patch deployment frontend -n debug-<dein-name> \
  -p '{"spec":{"template":{"metadata":{"labels":{"role":"api-consumer"}}}}}'
```

```
kubectl get pods -n debug-<dein-name> -l role=api-consumer
```

Neuen Pod-Namen holen und erneut testen:

```
FE_POD=$(kubectl get pod -n debug-<dein-name> -l app=frontend,role=api-consumer \
  -o jsonpath='{.items[0].metadata.name}')

kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

```
wget -qO- http://backend-svc --timeout=5
exit
```

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` — Verbindung OK.

---

## Problem 2: NetworkPolicy blockiert Backend zu Frontend

## Schritt 9: NetworkPolicy fuer Frontend anwenden

```
# vi 04-networkpolicy-frontend.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: backend-consumer
    ports:
    - protocol: TCP
      port: 8080
```

```
kubectl apply -f . -n debug-<dein-name>
```

## Schritt 10: Rueckweg vom Backend debuggen

```
BE_POD=$(kubectl get pod -n debug-<dein-name> -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo $BE_POD
```

```
kubectl debug -it $BE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=backend \
  --profile=general \
  -- sh
```

```
wget -qO- http://frontend-svc:8080 --timeout=5
exit
```

**Erwarteter Fehler:**
```
wget: download timed out
```

## Schritt 11: Diagnose und Fix

```
kubectl describe networkpolicy frontend-policy -n debug-<dein-name>
kubectl get pods -n debug-<dein-name> -l app=backend --show-labels
```

**Diagnose:** NetworkPolicy erlaubt nur `role=backend-consumer`. Backend-Pod hat
dieses Label nicht.

```
kubectl patch deployment backend -n debug-<dein-name> \
  -p '{"spec":{"template":{"metadata":{"labels":{"role":"backend-consumer"}}}}}'
```

```
kubectl get pods -n debug-<dein-name> -l role=backend-consumer
```

## Schritt 12: Rueckweg erneut testen

```
BE_POD=$(kubectl get pod -n debug-<dein-name> -l app=backend,role=backend-consumer \
  -o jsonpath='{.items[0].metadata.name}')

kubectl debug -it $BE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=backend \
  --profile=general \
  -- sh
```

```
wget -qO- http://frontend-svc:8080 --timeout=5
exit
```

**Erwartete Ausgabe:**
```
<title>Directory listing for /</title>
```

Rueckweg funktioniert.

---

## Aufraeumen

```
kubectl delete namespace debug-<dein-name>
```

---

## Zusammenfassung

| Problem | Fehlermeldung | Diagnose | Fix |
|---------|--------------|----------|-----|
| NetworkPolicy FE -> Backend | `timed out` | `kubectl describe networkpolicy` + `--show-labels` | Label `role=api-consumer` am Frontend |
| NetworkPolicy Backend -> FE | `timed out` | `kubectl describe networkpolicy` + `--show-labels` | Label `role=backend-consumer` am Backend |
