# Uebung: Custom Metriken mit eigener Demo-App

## Hintergrund

Kubernetes-Standard-Metriken (CPU, RAM, Restarts) kennen wir bereits.
In dieser Uebung deployen wir eine eigene App, die **fachliche Metriken**
bereitstellt - zum Beispiel aktive Nutzer oder verarbeitete Bestellungen.

Prometheus scrapt diese Metriken genauso wie alle anderen - der Unterschied
ist nur, dass wir sie selbst in der App definieren.

## Die Demo-App

Der vollstaendige Source-Code liegt im Repository:

- [app.py](demo-app/app.py) - Flask-App mit drei Metriken
- [Dockerfile](demo-app/Dockerfile) - wie das Image gebaut wird
- [requirements.txt](demo-app/requirements.txt) - Python-Abhaengigkeiten

Das fertige Image: `dockertrainereu/k8s-prometheus-demo:latest`

### Metriken der App (Port 8080)

| Metrik | Typ | Beschreibung |
|--------|-----|--------------|
| `http_requests_total` | Counter | Anzahl HTTP-Requests, nach Methode und Endpoint |
| `active_users` | Gauge | Aktuell aktive Nutzer (simuliert, 10-200) |
| `orders_processed_total` | Counter | Verarbeitete Bestellungen, nach Status (success/error) |

**Endpoints der App:**

| Endpoint | Beschreibung |
|----------|--------------|
| `/` | Startseite |
| `/buy` | Loest eine Bestellung aus (erhoet orders_processed_total) |
| `/metrics` | Prometheus-Metriken im Textformat (Port 8080) |

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests/custom-metriken
cd manifests/custom-metriken
```

## Schritt 2: Deployment

```
vi 01-deployment.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: demo-app
  template:
    metadata:
      labels:
        app: demo-app
    spec:
      containers:
      - name: demo-app
        image: dockertrainereu/k8s-prometheus-demo:latest
        ports:
        - name: metrics
          containerPort: 8080
```

## Schritt 3: Service

```
vi 02-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  labels:
    app: demo-app
spec:
  selector:
    app: demo-app
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
```

## Schritt 4: ServiceMonitor

Der ServiceMonitor sagt Prometheus: "Scrape alle Services mit diesem Label."

```
vi 03-servicemonitor.yml
```

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: demo-app
  namespace: monitoring
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: demo-app
  namespaceSelector:
    matchNames:
    - default
  endpoints:
  - port: metrics
    interval: 15s
    path: /metrics
```

## Schritt 5: Alles anwenden

```
kubectl apply -f 01-deployment.yml -f 02-service.yml
kubectl apply -f 03-servicemonitor.yml -n monitoring
```

```
kubectl get pods
kubectl get svc
kubectl -n monitoring get servicemonitor demo-app
```

## Schritt 6: Metriken direkt pruefen

Bevor wir Prometheus befragen, pruefen wir ob die App selbst Metriken liefert:

```
kubectl run metrics-check -it --rm --image=curlimages/curl \
  --restart=Never -- \
  curl -s http://demo-app.default.svc.cluster.local:8080/metrics
```

Erwartete Ausgabe (Auszug):

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="/metrics",method="GET"} 1.0
# HELP active_users Number of currently active users in the system
# TYPE active_users gauge
active_users 42.0
# HELP orders_processed_total Total number of processed orders
# TYPE orders_processed_total counter
orders_processed_total{status="success"} 3.0
```

## Schritt 7: In Prometheus pruefen

```
https://prometheus.<dein-name>.do.t3isp.de
```

Unter **Status → Targets** sollte nach ca. 30 Sekunden ein neues Target
`demo-app` mit State **UP** erscheinen.

Im **Graph**-Tab diese Abfragen ausprobieren:

```
active_users
```

```
rate(http_requests_total[5m])
```

```
rate(orders_processed_total{status="success"}[5m])
```

## Schritt 8: Last erzeugen und beobachten

In einem zweiten Terminal etwas Traffic erzeugen:

```
kubectl run load -it --rm --image=curlimages/curl --restart=Never -- \
  sh -c 'for i in $(seq 1 20); do curl -s http://demo-app.default.svc.cluster.local:8080/buy; done'
```

Dann in Prometheus erneut abfragen:

```
orders_processed_total
```

Der Counter sollte gestiegen sein.

## Schritt 9: In Grafana visualisieren

```
https://grafana.<dein-name>.do.t3isp.de
```

1. Links **Dashboards → New → New Dashboard**
2. **Add visualization**
3. Datasource: **Prometheus**
4. Metric: `active_users` eingeben
5. **Run queries** → Graph erscheint
6. Titel: "Aktive Nutzer" → **Apply**

Ein zweites Panel mit `rate(orders_processed_total{status="success"}[5m])`
zeigt die Bestellrate pro Sekunde.

## Aufraeumen

```
kubectl delete -f 01-deployment.yml -f 02-service.yml
kubectl delete -f 03-servicemonitor.yml -n monitoring
```
