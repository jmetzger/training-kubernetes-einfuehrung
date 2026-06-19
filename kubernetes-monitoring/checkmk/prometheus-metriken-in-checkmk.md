# Prometheus-Metriken in Checkmk integrieren

## Warum integrieren?

Checkmk und Prometheus haben unterschiedliche Staerken und ergaenzen sich:

| | Checkmk | Prometheus |
|---|---|---|
| **Kernstaerke** | Infrastructure-Checks, Service-Status, Alerting | Metriken, Time-Series, Dashboards |
| **Kubernetes** | Host/Service-Inventur, Piggyback-Objekte | CPU/Memory/Request-Rate, HPA |
| **Alerting** | Zentrale Notification-Engine | Alertmanager (eher technical) |

---

## Teil 1: Prometheus-Metriken in Checkmk einbinden

### Moeglichkeit 1: Checkmk Prometheus Special Agent (empfohlen)

Checkmk bringt einen eingebauten Special Agent mit, der direkt gegen die Prometheus HTTP-API
scraped und daraus native Checkmk-Checks erzeugt.

```
Setup -> Special Agents -> Prometheus -> Add rule
```

Parameter:

```
URL:          http://prometheus:9090
Auth:         optional (Basic/Bearer)
PromQL-Queries:
  - Service name: "pod_cpu_usage"
    PromQL:       rate(container_cpu_usage_seconds_total[5m])
    Unit:         1/s
    Levels:       warn=0.8, crit=0.9
```

Intern ruft Checkmk folgende Prometheus-Endpunkte ab:

```
GET /api/v1/query?query=<promql>
GET /api/v1/targets
```

Checkmk erzeugt aus jeder PromQL-Query einen eigenen Check-Service mit OK/WARN/CRIT-Status,
Performance-Daten (Graphen) und Einbindung in Checkmk-Notifications.

**Geeignet fuer:** Bestehende Prometheus-Infrastruktur, bei der Checkmk als zentrale
Alerting-Plattform genutzt werden soll.

---

### Moeglichkeit 2: OpenMetrics direkt scrapen (ohne Prometheus-Server)

Checkmk kann Prometheus-Exposition-Format direkt von Exportern lesen — ohne Prometheus-Server
als Mittelstufe.

```
Setup -> Services -> OpenMetrics Exporter -> Add rule
```

```
URL:      http://node-exporter:9100/metrics
Metriken:
  - node_cpu_seconds_total
  - node_memory_MemAvailable_bytes
```

**Vorteil:** Kein Prometheus noetig — Checkmk scraped Exporter direkt.

**Nachteil:** Kein PromQL, keine Aggregation ueber mehrere Targets.

---

### Moeglichkeit 3: Prometheus Alertmanager -> Checkmk Event Console

Prometheus-Alerts werden in die Checkmk Event Console weitergeleitet — Checkmk uebernimmt
dann Notification und Eskalation.

`alertmanager.yml`:

```
receivers:
  - name: checkmk
    webhook_configs:
      - url: http://checkmk/cmk/api/1.0/domain-types/event_console/actions/send_event/invoke
        http_config:
          bearer_token: <checkmk-api-token>
```

Checkmk-Seite:

```
Setup -> Event Console -> Rules -> New rule
  Match: source "alertmanager"
  Action: Create alert / Notification
```

**Geeignet fuer:** Teams, die Prometheus-Alerting behalten wollen, aber Checkmk fuer zentrale
Notifications (PagerDuty, Mail, Slack) nutzen.

---

### Moeglichkeit 4: Checkmk Enterprise — natives Kubernetes-Monitoring

In Checkmk Enterprise/Cloud gibt es keinen Umweg ueber Prometheus — Checkmk liest direkt
aus der Kubernetes-API und einem eigenen Cluster Collector:

```
Kubernetes API (:6443)            -> Checkmk Special Agent
Cluster Collector (/openmetrics)  -> Checkmk Special Agent
```

Der Cluster Collector (Helm-Deployment im Cluster) stellt einen OpenMetrics-Endpunkt bereit,
den Checkmk selbst scraped. Kein Prometheus involviert.

```
helm repo add checkmk https://checkmk.github.io/checkmk_kube_agent
helm install checkmk-cluster-collector checkmk/checkmk \
  --set clusterCollector.enabled=true \
  --set nodeCollector.enabled=true
```

---

## Teil 2: Anwendungsseitige Metriken einbinden

Fuer Metriken aus eigenen Applikationen, die nicht ueber den Cluster Collector kommen,
gibt es folgende Wege:

---

### Weg 1: OpenMetrics Special Agent — Checkmk scraped /metrics direkt

Wenn die App einen Prometheus-Exposition-Endpunkt hat (`/metrics`), kann Checkmk diesen
ohne Prometheus-Server direkt abfragen.

```
Setup -> Services -> Add rule -> OpenMetrics Exporter
```

```
URL:           http://<service-name>.<namespace>:8080/metrics
Metriken:
  - http_requests_total
  - orders_processed_total
  - active_users
Scrape-Interval: 60s
```

In Kubernetes erreicht Checkmk den App-Service ueber den cluster-internen DNS oder einen Ingress.

**Einschraenkung:** Keine PromQL-Aggregation — Checkmk verarbeitet die Metriken 1:1.

---

### Weg 2: Checkmk REST API — App pusht Metriken aktiv

Die App oder ein Sidecar/Adapter pusht Metriken via Checkmk REST API (Push-Modell statt Pull).

```
curl -X PUT \
  "https://checkmk/cmk/api/1.0/domain-types/metric/collections/all" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "host_name": "my-app-pod",
    "service_name": "orders_processed",
    "metrics": [
      {"name": "orders_total", "value": 4200, "unit": "count"}
    ]
  }'
```

**Geeignet fuer:** Apps ohne Pull-Endpunkt, z.B. nach einem Batch-Job oder einer
asynchronen Verarbeitung.

---

### Weg 3: Custom Active Check Plugin — Checkmk fragt App-API ab

Ein eigenes Plugin auf dem Checkmk-Server fragt die App direkt ab (REST-API,
proprietaeres Format) und gibt das Ergebnis als Checkmk-Check aus.

`/omd/sites/<site>/lib/nagios/plugins/check_myapp_metrics`:

```
#!/usr/bin/env python3
import requests, sys

resp = requests.get("http://my-app:8080/api/metrics")
data = resp.json()

orders = data["orders_per_minute"]
if orders < 10:
    print(f"CRIT - Orders/min: {orders} | orders={orders}")
    sys.exit(2)
elif orders < 50:
    print(f"WARN - Orders/min: {orders} | orders={orders}")
    sys.exit(1)
else:
    print(f"OK - Orders/min: {orders} | orders={orders}")
    sys.exit(0)
```

```
Setup -> Integrations -> Monitoring Agents -> Add rule -> Active checks (Custom)
  Command: check_myapp_metrics --host $HOSTNAME$
```

**Geeignet fuer:** Apps mit eigenem API-Format oder komplexer Logik
(mehrere Endpunkte kombinieren, Schwellwerte berechnen).

---

### Weg 4: Piggyback — CronJob im Cluster erzeugt Checkmk-Daten

Ein Kubernetes CronJob sammelt Metriken aus mehreren Pods/Apps und schickt sie als
Piggyback-Sektion an Checkmk. Jeder Pod erscheint als eigener virtueller Host.

```
# CronJob-Script: Metriken -> Checkmk-Piggyback-Format -> REST API push
piggyback_data = """
<<<<my-app-pod-1>>>>
<<<local>>>
0 orders_processed orders=4200;1000;500 Orders processed: 4200
<<<<>>>>
"""
requests.put("https://checkmk/.../piggyback", data=piggyback_data, ...)
```

**Geeignet fuer:** Dynamische Pod-Landschaften, wo fuer jeden Pod ein eigener
virtueller Host in Checkmk erscheinen soll.

---

## Empfehlung je nach Szenario

### Architektur-Entscheidung

**Szenario A: Nur Checkmk (Enterprise)**

```
K8s API + Cluster Collector -> Checkmk Special Agent
-> Checkmk hat Inventory, Checks, Notifications
-> Prometheus nicht noetig
```

**Szenario B: Nur Prometheus/Grafana**

```
kube-state-metrics + node-exporter -> Prometheus -> Grafana
-> Optimal fuer Dashboards, HPA, Custom-Metriken
-> Kein zentrales IT-Monitoring
```

**Szenario C: Hybrid (empfohlen fuer Enterprise-Umgebungen)**

```
Prometheus/Grafana   -> Metriken, Dashboards, HPA
Checkmk              -> Service-Status, IT-Monitoring, Notifications
Alertmanager         -> leitet kritische Alerts -> Checkmk Event Console
```

### Welches Tool fuer welche Frage?

| Frage | Tool |
|---|---|
| Ist mein Pod/Service up? | Checkmk |
| Wie ist die Request-Rate? | Prometheus |
| CPU/Memory-Trend ueber 30 Tage? | Prometheus / Grafana |
| Wer bekommt den Alert um 3 Uhr? | Checkmk (Notification Routing) |
| HPA skalieren nach Custom-Metrik? | Prometheus (KEDA/HPA) |

### Anwendungsmetriken: Welcher Weg?

| Situation | Empfehlung |
|---|---|
| App hat `/metrics` (Prometheus-Format) | Weg 1 — OpenMetrics Special Agent |
| App hat eigene REST-API | Weg 3 — Custom Active Check Plugin |
| App hat kein Pull-Endpoint (Batch, Jobs) | Weg 2 — REST API Push nach Job-Ende |
| Viele dynamische Pods, einzeln sichtbar | Weg 4 — Piggyback via CronJob |
| Prometheus bereits vorhanden | Prometheus Special Agent mit PromQL (Teil 1, Moeglichkeit 1) |
