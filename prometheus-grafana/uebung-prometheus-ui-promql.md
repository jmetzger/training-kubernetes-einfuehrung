# Uebung: Prometheus UI und PromQL

## Hintergrund

Prometheus sammelt Metriken per Pull-Modell: alle 15 Sekunden ruft es
bei jedem bekannten Target den Endpunkt `/metrics` ab und speichert die
Werte in seiner Time-Series-Datenbank (TSDB).

```
App/Service
  └─ /metrics (HTTP)
       │
       │  Prometheus scraped alle 15s
       ▼
  Prometheus TSDB
       │
       │  PromQL-Query
       ▼
  Grafana / Browser-UI
```

In dieser Uebung schauen wir uns diesen Weg von innen an:
rohe Metriken → Prometheus Targets → PromQL-Abfragen.

## Voraussetzung

Der kube-prometheus-stack ist installiert (siehe install-with-helm.md).
Prometheus laeuft im Namespace `monitoring`.

Port-Forward starten (falls kein Ingress vorhanden):

```
kubectl -n monitoring port-forward svc/prometheus-prometheus 9090 &
```

SSH-Tunnel vom lokalen Rechner (in separatem Terminal):

```
ssh -L 9090:localhost:9090 tln1@<server-ip>
```

Dann im Browser:

```
http://localhost:9090
```

## Schritt 1: Targets - was scrapt Prometheus?

Im Prometheus-Browser-UI oben auf **Status → Targets** klicken.

Hier sieht man alle Endpoints, die Prometheus aktiv abfragt:

- **State UP** (gruen) = Prometheus erreicht den Endpoint und bekommt Metriken
- **State DOWN** (rot) = Endpoint nicht erreichbar

Wichtige Targets im kube-prometheus-stack:

| Target | Was es liefert |
|--------|----------------|
| `node-exporter` | CPU, RAM, Disk, Netzwerk pro Node |
| `kube-state-metrics` | Zustand von Pods, Deployments, ReplicaSets |
| `kubelet` / `cAdvisor` | Container-Ressourcen (CPU/RAM pro Container) |
| `prometheus` selbst | Interne Prometheus-Metriken |
| `alertmanager` | Alertmanager-Metriken |

**Frage zum Nachdenken:** Wie weiss Prometheus, welche Pods es scrapen soll?
→ Antwort: ServiceMonitor CRDs (dazu spaeter mehr)

## Schritt 2: /metrics direkt ansehen

Prometheus zieht Metriken von HTTP-Endpunkten. Wir koennen uns dieselben
Rohdaten direkt anschauen.

Den node-exporter Service anschauen:

```
kubectl -n monitoring get svc | grep node
kubectl -n monitoring port-forward svc/node-exporter 9100 &
```

Im Browser:

```
http://localhost:9100/metrics
```

Hier sieht man das Rohformat:

```
# HELP node_cpu_seconds_total Seconds the CPUs spent in each mode.
# TYPE node_cpu_seconds_total counter
node_cpu_seconds_total{cpu="0",mode="idle"} 12345.67
node_cpu_seconds_total{cpu="0",mode="system"} 234.56
node_cpu_seconds_total{cpu="0",mode="user"} 567.89
```

Jede Zeile hat das Format:
```
metrik_name{label1="wert1", label2="wert2"} zahlenwert
```

Port-Forward wieder stoppen:

```
kill %2
```

## Schritt 3: Erste PromQL-Abfragen im Prometheus UI

Zurueck im Prometheus UI auf den Tab **Graph** wechseln.

Im Suchfeld die folgenden Abfragen einzeln eingeben und auf **Execute** klicken.

### 3.1 Welche Targets sind erreichbar?

```
up
```

Ergebnis: Eine 1 = erreichbar, eine 0 = nicht erreichbar.
Labels zeigen welcher Job und welcher Instance-Endpoint gemeint ist.

### 3.2 Alle laufenden Pods im Cluster

```
kube_pod_info
```

Jede Zeile steht fuer einen Pod. Labels enthalten Namespace, Pod-Name, Node.

### 3.3 Wieviele Pods laufen pro Namespace?

```
count by (namespace) (kube_pod_info)
```

`count by (namespace)` gruppiert die Ergebnisse und zaehlt.

### 3.4 CPU-Verbrauch pro Container (letzte 5 Minuten)

```
rate(container_cpu_usage_seconds_total{container!=""}[5m])
```

`rate()` berechnet den Durchschnitt pro Sekunde ueber 5 Minuten.
Container mit leerem Namen sind Infrastruktur-Container, deshalb der Filter.

### 3.5 RAM-Verbrauch pro Container in MB

```
container_memory_usage_bytes{container!=""} / 1024 / 1024
```

Ergebnis direkt in Megabyte.

### 3.6 Wieviele Replicas eines Deployments sind verfuegbar?

```
kube_deployment_status_replicas_available
```

Sieht man sofort, wenn ein Deployment nicht alle Replicas hat.

### 3.7 Pods die neu gestartet wurden (Restarts)

```
kube_pod_container_status_restarts_total > 0
```

Zeigt alle Container, die mindestens einmal neu gestartet wurden.
Sehr nuetzlich fuer CrashLoopBackOff-Diagnose.

## Schritt 4: Graph-Ansicht verwenden

Eine Abfrage eingeben, dann auf den Tab **Graph** (neben "Table") klicken:

```
rate(container_cpu_usage_seconds_total{container!=""}[5m])
```

Zeitraum oben rechts einstellen (z.B. **15m** fuer die letzten 15 Minuten).

Der Graph zeigt den zeitlichen Verlauf - genau diese Daten fragt Grafana
per PromQL ab und stellt sie als Dashboard dar.

## Schritt 5: Labels verstehen

Labels sind das Herzstuck von Prometheus. Jede Metrik kann beliebig viele
Labels haben, nach denen gefiltert und gruppiert werden kann.

Gezielt nach einem Namespace filtern:

```
kube_pod_info{namespace="monitoring"}
```

Nach mehreren Werten filtern (OR mit Regex):

```
kube_pod_info{namespace=~"monitoring|default"}
```

Label aus dem Ergebnis herauslassen:

```
sum by (node) (kube_pod_info)
```

Zaehlt Pods pro Node (alles ausser Node-Label wird zusammengefasst).

## PromQL Spickzettel

| Anwendungsfall | Abfrage |
|----------------|---------|
| Alle Targets erreichbar? | `up` |
| CPU-Rate pro Container | `rate(container_cpu_usage_seconds_total{container!=""}[5m])` |
| RAM pro Container (MB) | `container_memory_usage_bytes{container!=""} / 1024 / 1024` |
| Pods pro Namespace | `count by (namespace) (kube_pod_info)` |
| Deployment-Replicas OK? | `kube_deployment_status_replicas_available` |
| Container-Restarts | `kube_pod_container_status_restarts_total > 0` |
| Node-Auslastung CPU % | `100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)` |
| Freier RAM pro Node (GB) | `node_memory_MemAvailable_bytes / 1024 / 1024 / 1024` |
| HTTP-Requests pro Sekunde | `rate(http_requests_total[5m])` |

Die letzte Zeile (http_requests_total) erscheint nur, wenn eine eigene App
diese Metrik exposed - dazu spaeter mehr in der Uebung zu Custom Metriken.

## Naechster Schritt: Grafana

Dieselben PromQL-Abfragen aus dieser Uebung kann man direkt in Grafana
als Dashboard-Panel verwenden:

```
kubectl -n monitoring get pods | grep grafana
kubectl -n monitoring port-forward <grafana-pod-name> 3000 &
```

SSH-Tunnel:

```
ssh -L 3000:localhost:3000 tln1@<server-ip>
```

Browser:

```
http://localhost:3000
# Login: admin / prom-operator
```

**Connections → Data Sources** zeigt, dass Grafana bereits mit Prometheus
verbunden ist. Unter **Dashboards** sind fertige Kubernetes-Dashboards
bereits importiert.
