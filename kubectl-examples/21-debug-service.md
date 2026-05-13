# Debugging: Service-Verbindungsprobleme mit kubectl debug

## Hintergrund

Wenn ein Frontend den Backend-Service nicht erreichen kann, gibt es zwei haeufige
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
kubectl apply -f 01-backend.yml -n debug-<dein-name>
```

## Schritt 3: Frontend Deployment anlegen

Das Frontend laeuft als minimales Python-Image - kein curl, wget oder nc vorhanden.

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
        command: ["python", "-c", "import time; time.sleep(86400)"]
```

```
kubectl apply -f 02-frontend.yml -n debug-<dein-name>
```

```
kubectl get pods -n debug-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 1/1     Running   0          30s
frontend-xxx                1/1     Running   0          20s
```

---

## Problem 1: Falscher Service-Selector - keine Endpoints

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

## Schritt 5: Endpoints und Service-Selector pruefen

```
kubectl get endpoints backend-svc -n debug-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME          ENDPOINTS   AGE
backend-svc   <none>      2m
```

Keine Endpoints - der Service findet keine Pods. Selector mit Pod-Labels vergleichen:

```
kubectl describe service backend-svc -n debug-<dein-name> | grep -E 'Selector|Port|Endpoint'
kubectl get pods -n debug-<dein-name> -l app=backend --show-labels
```

**Ausgabe:**
```
Selector:    app=backend-api
Port:        80/TCP
Endpoints:   <none>

NAME          LABELS
backend-xxx   app=backend,tier=backend,...
```

**Diagnose:** Service sucht `app=backend-api`, Pods haben `app=backend`.

## Schritt 6: Fix - Selector im Service korrigieren

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
exit
```

**Erwartete Ausgabe:** `<h1>Welcome to nginx!</h1>` - Verbindung OK.

---

## Problem 2: Falscher targetPort - Endpoint vorhanden, trotzdem kein Zugriff

Jetzt simulieren wir einen neuen Fehler - der targetPort zeigt auf einen Port,
auf dem kein Prozess lauscht.

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
```

**Erwartete Ausgabe:**
```
NAME          ENDPOINTS           AGE
backend-svc   10.x.x.x:8080      5m
```

Endpoint existiert - aber Port 8080! nginx lauscht auf Port 80.

```
kubectl describe service backend-svc -n debug-<dein-name> | grep -E 'Port|Target|Endpoint'
```

**Ausgabe:**
```
Port:        <unset>  80/TCP
TargetPort:  8080/TCP
Endpoints:   10.x.x.x:8080
```

**Diagnose:** TargetPort zeigt auf 8080, aber der Container-Port ist 80.

```
kubectl get pods -n debug-<dein-name> -l app=backend -o jsonpath='{.items[0].spec.containers[0].ports}'
```

**Ausgabe:**
```
[{"containerPort":80,"protocol":"TCP"}]
```

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

## Aufraeumen

```
kubectl delete namespace debug-<dein-name>
```

## Zusammenfassung

| Problem | `kubectl get endpoints` | Diagnose | Fix |
|---------|------------------------|----------|-----|
| Falscher Selector | `<none>` | `describe service` → Selector falsch | Selector anpassen |
| Falscher targetPort | `10.x.x.x:8080` (falsche Port) | `describe service` → TargetPort falsch | targetPort anpassen |

**Merkhilfe:** Endpoints leer → Selector-Problem. Endpoints vorhanden aber falsche Port → targetPort-Problem.
