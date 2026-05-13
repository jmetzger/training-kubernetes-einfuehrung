# Debugging: FE zu Backend Verbindungen mit kubectl debug und NetworkPolicy

## Hintergrund

In produktiven Umgebungen laufen Container oft als minimale Images ohne Debug-Tools
(curl, wget, nc). Wenn eine Verbindung zwischen Pods nicht funktioniert, zeigt die
Fehlermeldung bereits in welche Richtung man schauen muss:

| Fehlerbild | Ursache | Diagnose-Befehl |
|-----------|---------|-----------------|
| `Connection refused` | Service-Selector passt nicht - keine Endpoints | `kubectl get endpoints` |
| `Connection timed out` | NetworkPolicy blockiert den Traffic | `kubectl describe networkpolicy` |

`kubectl debug` schleust einen ephemeral Container mit Debug-Tools in einen laufenden
Pod ein - ohne den Pod neu starten zu muessen.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 15-debug-networkpolicy
cd 15-debug-networkpolicy
```

## Schritt 2: Backend Deployment und Service anlegen

Achtung: Im Service steckt ein Fehler - den sollt ihr selbst finden.

```
nano 01-backend.yml
```

```
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
        tier: backend
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
    app: backend-api
  ports:
  - port: 80
    targetPort: 80
```

```
kubectl apply -f 01-backend.yml -n debug-<dein-name>
```

## Schritt 3: Frontend Deployment und Service anlegen

Das Frontend laeuft als minimales Python-Image (kein curl, wget, nc) und startet
einen einfachen HTTP-Server auf Port 8080.

```
nano 02-frontend.yml
```

```
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
        tier: frontend
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
kubectl apply -f 02-frontend.yml -n debug-<dein-name>
```

Warten bis beide Pods laufen:

```
kubectl get pods -n debug-<dein-name>
kubectl get services -n debug-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 1/1     Running   0          30s
frontend-xxx                1/1     Running   0          20s

NAME           TYPE        CLUSTER-IP    PORT(S)
backend-svc    ClusterIP   10.x.x.x      80/TCP
frontend-svc   ClusterIP   10.x.x.x      8080/TCP
```

---

## Problem 1: Connection refused - Fehlkonfigurierter Service-Selector

## Schritt 4: Tools im Frontend pruefen

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

## Schritt 5: kubectl debug - Verbindung vom Frontend zum Backend testen

```
kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

Im Debug-Container:

```
nslookup backend-svc
wget -qO- http://backend-svc --timeout=5
```

**Erwartete Ausgabe:**
```
Name:   backend-svc.debug-<dein-name>.svc.cluster.local
Address: 10.x.x.x

wget: can't connect to remote host (10.x.x.x): Connection refused
```

DNS loest auf - aber `Connection refused` bedeutet: kein Endpoint hinter dem Service.

```
exit
```

## Schritt 6: Endpoints pruefen und Ursache finden

```
kubectl get endpoints backend-svc -n debug-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME          ENDPOINTS   AGE
backend-svc   <none>      2m
```

Selector des Service mit Pod-Labels vergleichen:

```
kubectl get service backend-svc -n debug-<dein-name> -o jsonpath='{.spec.selector}'
kubectl get pods -n debug-<dein-name> -l app=backend --show-labels
```

**Diagnose:** Service sucht `app=backend-api`, Pods haben `app=backend`.

## Schritt 7: Fix - Service-Selector korrigieren

```
kubectl patch service backend-svc -n debug-<dein-name> \
  -p '{"spec":{"selector":{"app":"backend"}}}'
```

```
kubectl get endpoints backend-svc -n debug-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME          ENDPOINTS      AGE
backend-svc   10.x.x.x:80   3m
```

Erneut testen:

```
kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

```
wget -qO- http://backend-svc --timeout=5
```

**Erwartete Ausgabe:**
```
<h1>Welcome to nginx!</h1>
```

```
exit
```

---

## Problem 2: Connection timed out - NetworkPolicy blockiert FE zu Backend

## Schritt 8: NetworkPolicy fuer Backend anwenden

```
nano 03-networkpolicy-backend.yml
```

```
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
kubectl apply -f 03-networkpolicy-backend.yml -n debug-<dein-name>
```

## Schritt 9: Verbindung testen - anderes Fehlerbild

```
kubectl debug -it $FE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=frontend \
  --profile=general \
  -- sh
```

```
wget -qO- http://backend-svc --timeout=5
```

**Erwartete Ausgabe:**
```
wget: download timed out
```

Diesmal ein **Timeout** statt `Connection refused`. Endpoints existieren, aber die
NetworkPolicy blockiert den Traffic.

```
exit
```

## Schritt 10: NetworkPolicy und Labels pruefen

```
kubectl describe networkpolicy backend-policy -n debug-<dein-name>
kubectl get pods -n debug-<dein-name> --show-labels
```

**Diagnose:** NetworkPolicy erlaubt nur `role=api-consumer`. Frontend-Pod hat dieses
Label nicht.

## Schritt 11: Fix - Label zum Frontend Deployment hinzufuegen

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

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` - Verbindung OK.

---

## Problem 3: Rueckweg - Backend zu Frontend

## Schritt 12: NetworkPolicy fuer Frontend anwenden

```
nano 04-networkpolicy-frontend.yml
```

```
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
kubectl apply -f 04-networkpolicy-frontend.yml -n debug-<dein-name>
```

## Schritt 13: Rueckweg vom Backend debuggen

Backend-Pod-Namen holen:

```
BE_POD=$(kubectl get pod -n debug-<dein-name> -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo $BE_POD
```

Debug-Container im Backend-Pod starten:

```
kubectl debug -it $BE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=backend \
  --profile=general \
  -- sh
```

Im Debug-Container:

```
nslookup frontend-svc
wget -qO- http://frontend-svc:8080 --timeout=5
```

**Erwartete Ausgabe:**
```
Name:   frontend-svc.debug-<dein-name>.svc.cluster.local
Address: 10.x.x.x

wget: download timed out
```

DNS loest auf, aber Timeout - NetworkPolicy blockiert.

```
exit
```

## Schritt 14: Diagnose und Fix

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

## Schritt 15: Rueckweg erneut testen

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

## Aufraeumen

```
kubectl delete namespace debug-<dein-name>
```

## Zusammenfassung

| Problem | Fehlermeldung | Diagnose | Fix |
|---------|--------------|----------|-----|
| Falscher Service-Selector | `Connection refused` | `kubectl get endpoints` | Selector anpassen |
| NetworkPolicy FE -> Backend | `timed out` | `kubectl describe networkpolicy` | Label `role=api-consumer` am Frontend |
| NetworkPolicy Backend -> FE | `timed out` | `kubectl describe networkpolicy` | Label `role=backend-consumer` am Backend |
