# Uebung: Eigene App-Metriken mit ServiceMonitor

## Hintergrund

Prometheus weiss nicht automatisch, welche Pods gescrapt werden sollen.
Der kube-prometheus-stack verwendet dafuer **ServiceMonitor**-Objekte:
Ein ServiceMonitor ist eine Custom Resource (CRD), die beschreibt,
wo und wie Prometheus Metriken abholen soll.

```
Deployment (App mit /metrics)
  └─ Service (Port 8080)
       │
       │  ServiceMonitor zeigt auf den Service
       ▼
  Prometheus Operator
       │  entdeckt ServiceMonitor, konfiguriert Prometheus automatisch
       ▼
  Prometheus scrapt /metrics alle 15s
```

In dieser Uebung deployen wir eine fertige Demo-App, die drei eigene
Metriken bereitstellt, verbinden sie per ServiceMonitor mit Prometheus
und fragen die Metriken per PromQL ab.

### Was die Demo-App misst

| Metrik | Typ | Beschreibung |
|--------|-----|--------------|
| `http_requests_total` | Counter | HTTP-Anfragen nach Methode + Endpoint |
| `active_users` | Gauge | Simulierte aktive Nutzer (10–200) |
| `orders_processed_total` | Counter | Bestellungen nach Status (success/error) |

Die App laeuft auf Port `8080` und stellt Metriken unter `/metrics` bereit.

## Voraussetzung

kube-prometheus-stack ist installiert (siehe `install-with-helm-ingress.md`).

## Schritt 1: Namespace und Deployment

```
kubectl create namespace demo-app
```

```
vi demo-app.yml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: demo-app
  namespace: demo-app
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
        - containerPort: 8080
          name: http
---
apiVersion: v1
kind: Service
metadata:
  name: demo-app
  namespace: demo-app
  labels:
    app: demo-app
spec:
  selector:
    app: demo-app
  ports:
  - name: http
    port: 8080
    targetPort: 8080
```

```
kubectl apply -f demo-app.yml
```

```
kubectl -n demo-app get pods
```

## Schritt 2: /metrics direkt pruefen

Bevor wir Prometheus einbinden, schauen wir uns die Rohdaten direkt an:

```
kubectl run check -it --rm --image=curlimages/curl \
  --restart=Never -n demo-app -- \
  curl -s http://demo-app.demo-app.svc.cluster.local:8080/metrics
```

Erwartet werden Zeilen wie:

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{endpoint="/",method="GET"} 3.0
# HELP active_users Number of currently active users in the system
# TYPE active_users gauge
active_users 47.0
# HELP orders_processed_total Total number of processed orders
# TYPE orders_processed_total counter
orders_processed_total{status="error"} 2.0
orders_processed_total{status="success"} 9.0
```

## Schritt 3: ServiceMonitor erstellen

Damit Prometheus die App erkennt, brauchen wir einen ServiceMonitor.
Das Label `release: prometheus` ist entscheidend — damit weiss der
Prometheus Operator, dass er diesen ServiceMonitor verwalten soll.

```
vi servicemonitor.yml
```

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: demo-app
  namespace: demo-app
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: demo-app
  namespaceSelector:
    matchNames:
    - demo-app
  endpoints:
  - port: http
    interval: 15s
    path: /metrics
    honorLabels: true
```

> **Hinweis zu `honorLabels: true`:** Die App verwendet selbst ein Label
> namens `endpoint` (z.B. `endpoint="/buy"`). Prometheus wuerde dieses
> normalerweise in `exported_endpoint` umbenennen, weil es intern auch ein
> `endpoint`-Label fuer den Port-Namen vergibt. Mit `honorLabels: true`
> gewinnen die App-Labels — die PromQL-Abfragen funktionieren dann wie erwartet.

```
kubectl apply -f servicemonitor.yml
```

```
kubectl -n demo-app get servicemonitor
```

## Schritt 4: Target in Prometheus pruefen

Im Prometheus-Browser-UI **Status → Targets** oeffnen.

Nach etwa 30 Sekunden erscheint ein neues Target:

```
serviceMonitor/demo-app/demo-app/0
```

State muss **UP** (gruen) sein.

Falls das Target nicht erscheint: kurz warten und Seite neu laden.
Der Prometheus Operator braucht einen Moment, um den ServiceMonitor zu verarbeiten.

## Schritt 5: PromQL auf eigene Metriken

Im Prometheus UI den Tab **Graph** oeffnen.

### 5.1 Alle Metriken der Demo-App sehen

```
{job="demo-app"}
```

Zeigt alle Metriken, die von diesem Job gesammelt werden.

### 5.2 Aktive Nutzer (aktueller Wert)

```
active_users
```

Gauge-Wert aendert sich alle 5 Sekunden (simuliert durch die App).
Im **Graph**-Tab sieht man den Verlauf.

### 5.3 HTTP-Requests pro Sekunde

```
rate(http_requests_total[5m])
```

Counter allein ist wenig aussagekraeftig — `rate()` berechnet die
Aenderungsrate pro Sekunde ueber ein Zeitfenster.

### 5.4 Nur Requests auf einen bestimmten Endpoint

```
rate(http_requests_total{endpoint="/buy"}[5m])
```

Labels koennen den Datenstrom einschraenken.

### 5.5 Erfolgsquote der Bestellungen in Prozent

```
rate(orders_processed_total{status="success"}[5m])
/
rate(orders_processed_total[5m])
* 100
```

Teilen zweier Rates ergibt eine Quote. So sieht man auf einem Blick,
ob mehr Fehler als normal auftreten.

### 5.6 Requests selbst ausloesen

In einem zweiten Terminal etwas Last erzeugen:

```
kubectl run load -it --rm --image=curlimages/curl \
  --restart=Never -n demo-app -- sh -c \
  'for i in $(seq 1 20); do curl -s http://demo-app.demo-app.svc.cluster.local:8080/buy > /dev/null; done'
```

Danach im Prometheus-Graph beobachten, wie `http_requests_total` steigt.

## Schritt 6: Panel in Grafana erstellen

```
https://grafana.<dein-name>.do.t3isp.de
# Login: admin / DEIN-PASSWORT
```

1. Links auf **Dashboards** → **New** → **New dashboard** klicken
2. **Add visualization** klicken
3. Datenquelle **Prometheus** auswaehlen
4. Unten im Query-Feld eingeben:

```
rate(http_requests_total[5m])
```

5. Rechts den Panel-Typ auf **Time series** lassen
6. Oben rechts **Apply** klicken, dann **Save dashboard**

Damit ist eine eigene App per ServiceMonitor an Prometheus angebunden
und die Metriken laufen in Grafana.

## PromQL Spickzettel fuer diese Uebung

| Ziel | Abfrage |
|------|---------|
| Alle App-Metriken | `{job="demo-app"}` |
| Aktive Nutzer (aktuell) | `active_users` |
| HTTP-Rate gesamt | `rate(http_requests_total[5m])` |
| HTTP-Rate nach Endpoint | `rate(http_requests_total{endpoint="/buy"}[5m])` |
| Erfolgsrate Bestellungen % | `rate(orders_processed_total{status="success"}[5m]) / rate(orders_processed_total[5m]) * 100` |

## Aufraeumen

```
kubectl delete namespace demo-app
```

Der ServiceMonitor und das Target verschwinden automatisch aus Prometheus.
