# Debugging: Service-Verbindungsprobleme mit kubectl debug

## Hintergrund

Wenn Pods sich gegenseitig nicht erreichen koennen, gibt es zwei haeufige
Ursachen - beide zeigen `Connection refused`, aber aus unterschiedlichen Gruenden:

| Fehlerbild | Ursache | Erkennungsmerkmal |
|-----------|---------|-------------------|
| `Connection refused` | Falscher Service-Selector - keine Endpoints | `kubectl get endpoints` zeigt `<none>` |
| `Connection refused` | Falscher targetPort - Endpoint zeigt falsche Port | `kubectl get endpoints` zeigt Endpoint mit falscher Port |

`kubectl debug` schleust einen ephemeral Container mit Debug-Tools in einen laufenden
Pod ein - ohne den Pod neu starten zu muessen.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 21-debug-service
cd 21-debug-service
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
kubectl create ns debug-<dein-name>
kubectl apply -f 01-backend.yml -n debug-<dein-name>
```

## Schritt 3: Frontend Deployment und Service anlegen

Das Frontend laeuft als minimales Python-Image (kein curl, wget, nc) und startet
einen einfachen HTTP-Server auf Port 8080.

Achtung: Auch im Frontend-Service steckt ein Fehler.

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
    app: frontend-api
  ports:
  - port: 8080
    targetPort: 8080
```

```
kubectl apply -f 02-frontend.yml -n debug-<dein-name>
```

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

## Problem 1: FE zu Backend - Falscher Selector, keine Endpoints

## Schritt 4: kubectl debug - Verbindung testen

```
FE_POD=$(kubectl get pod -n debug-<dein-name> -l app=frontend -o jsonpath='{.items[0].metadata.name}')
echo $FE_POD
```

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

DNS loest auf - aber `Connection refused`. Kein Listener hinter dem Service.

```
exit
```

## Schritt 5: Endpoints und Selector pruefen

```
kubectl get endpoints backend-svc -n debug-<dein-name>
kubectl describe service backend-svc -n debug-<dein-name> | grep -E 'Selector|Port|Endpoint'
kubectl get pods -n debug-<dein-name> -l app=backend --show-labels
```

**Diagnose:** Service sucht `app=backend-api`, Pods haben `app=backend`.

## Schritt 6: Fix - Selector korrigieren

```
kubectl patch service backend-svc -n debug-<dein-name> \
  -p '{"spec":{"selector":{"app":"backend"}}}'
```

```
kubectl get endpoints backend-svc -n debug-<dein-name>
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
exit
```

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` - Verbindung OK.

---

## Problem 2: FE zu Backend - Falscher targetPort

## Schritt 7: targetPort kaputt konfigurieren

```
kubectl patch service backend-svc -n debug-<dein-name> \
  -p '{"spec":{"ports":[{"port":80,"targetPort":8080}]}}'
```

## Schritt 8: kubectl debug - Verbindung testen

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
wget: can't connect to remote host (10.x.x.x): Connection refused
```

Wieder `Connection refused` - aber diesmal aus anderem Grund.

```
exit
```

## Schritt 9: Diagnose - Endpoint vorhanden aber Port falsch

```
kubectl get endpoints backend-svc -n debug-<dein-name>
kubectl describe service backend-svc -n debug-<dein-name> | grep -E 'Port|Target|Endpoint'
kubectl get pods -n debug-<dein-name> -l app=backend -o jsonpath='{.items[0].spec.containers[0].ports}'
```

**Diagnose:** TargetPort zeigt auf 8080, Container lauscht auf 80.

## Schritt 10: Fix - targetPort korrigieren

```
kubectl patch service backend-svc -n debug-<dein-name> \
  -p '{"spec":{"ports":[{"port":80,"targetPort":80}]}}'
```

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

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` - Verbindung OK.

---

## Problem 3: Rueckweg Backend zu Frontend - Falscher Selector

## Schritt 11: kubectl debug auf Backend-Pod - Verbindung zum Frontend testen

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

Im Debug-Container:

```
nslookup frontend-svc
wget -qO- http://frontend-svc:8080 --timeout=5
```

**Erwartete Ausgabe:**
```
Name:   frontend-svc.debug-<dein-name>.svc.cluster.local
Address: 10.x.x.x

wget: can't connect to remote host (10.x.x.x): Connection refused
```

```
exit
```

## Schritt 12: Endpoints und Selector pruefen

```
kubectl get endpoints frontend-svc -n debug-<dein-name>
kubectl describe service frontend-svc -n debug-<dein-name> | grep -E 'Selector|Port|Endpoint'
kubectl get pods -n debug-<dein-name> -l app=frontend --show-labels
```

**Diagnose:** Service sucht `app=frontend-api`, Pods haben `app=frontend`.

## Schritt 13: Fix - Selector korrigieren

```
kubectl patch service frontend-svc -n debug-<dein-name> \
  -p '{"spec":{"selector":{"app":"frontend"}}}'
```

```
kubectl get endpoints frontend-svc -n debug-<dein-name>
```

Erneut testen:

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

**Erwartete Ausgabe:** `<title>Directory listing for /</title>` - Verbindung OK.

---

## Problem 4: Rueckweg Backend zu Frontend - Falscher targetPort

## Schritt 14: targetPort kaputt konfigurieren

```
kubectl patch service frontend-svc -n debug-<dein-name> \
  -p '{"spec":{"ports":[{"port":8080,"targetPort":9090}]}}'
```

## Schritt 15: kubectl debug - Verbindung testen

```
kubectl debug -it $BE_POD -n debug-<dein-name> \
  --image=busybox:1.36 \
  --target=backend \
  --profile=general \
  -- sh
```

```
wget -qO- http://frontend-svc:8080 --timeout=5
```

**Erwartete Ausgabe:**
```
wget: can't connect to remote host (10.x.x.x): Connection refused
```

```
exit
```

## Schritt 16: Diagnose und Fix

```
kubectl get endpoints frontend-svc -n debug-<dein-name>
kubectl describe service frontend-svc -n debug-<dein-name> | grep -E 'Port|Target|Endpoint'
kubectl get pods -n debug-<dein-name> -l app=frontend -o jsonpath='{.items[0].spec.containers[0].ports}'
```

**Diagnose:** TargetPort zeigt auf 9090, Container lauscht auf 8080.

```
kubectl patch service frontend-svc -n debug-<dein-name> \
  -p '{"spec":{"ports":[{"port":8080,"targetPort":8080}]}}'
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

**Erwartete Ausgabe:** `<title>Directory listing for /</title>` - Rueckweg OK.

## Aufraeumen

```
kubectl delete namespace debug-<dein-name>
```

## Zusammenfassung

| Problem | Richtung | `kubectl get endpoints` | Diagnose | Fix |
|---------|----------|------------------------|----------|-----|
| Falscher Selector | FE → Backend | `<none>` | Selector passt nicht zu Pod-Labels | Selector anpassen |
| Falscher targetPort | FE → Backend | Port falsch | TargetPort != ContainerPort | targetPort anpassen |
| Falscher Selector | Backend → FE | `<none>` | Selector passt nicht zu Pod-Labels | Selector anpassen |
| Falscher targetPort | Backend → FE | Port falsch | TargetPort != ContainerPort | targetPort anpassen |

**Merkhilfe:** Endpoints leer → Selector-Problem. Endpoints vorhanden aber falsche Port → targetPort-Problem.
