# Uebung: Grafana Dashboards

## Voraussetzung

kube-prometheus-stack ist installiert (siehe `install-with-helm-ingress.md`).

```
https://grafana.<dein-name>.do.t3isp.de
# Login: admin / DEIN-PASSWORT (aus values.yml)
```

## Schritt 1: Vorinstallierte Dashboards erkunden

Der kube-prometheus-stack liefert 27 fertige Dashboards mit.
Diese sind bereits mit Prometheus verbunden und zeigen Cluster-Metriken.

Links im Menü auf **Dashboards** klicken.

Interessante Dashboards zum Anschauen:

| Dashboard | Was es zeigt |
|-----------|-------------|
| Kubernetes / Compute Resources / Cluster | CPU + RAM des gesamten Clusters |
| Kubernetes / Compute Resources / Node (Pods) | Ressourcen pro Node aufgeschluesselt nach Pods |
| Kubernetes / Compute Resources / Pod | CPU + RAM eines einzelnen Pods |
| Node Exporter / Nodes | Disk, Netzwerk, CPU-Modi pro Node |
| Alertmanager / Overview | Status der konfigurierten Alerts |

**Aufgabe:** Dashboard "Kubernetes / Compute Resources / Cluster" oeffnen
und den aktuellen CPU- und RAM-Verbrauch des Clusters ablesen.

## Schritt 2: Dashboard von grafana.com importieren

grafana.com stellt tausende Community-Dashboards bereit.
Jedes hat eine ID — damit kann man es direkt in Grafana laden.

### Dashboard-ID 15760 importieren (Kubernetes Views - Pods)

1. Links im Menü auf **Dashboards** → **New** → **Import** klicken
2. Im Feld **Find and import dashboards** die ID eingeben:

```
15760
```

3. Auf **Load** klicken
4. Bei **Prometheus** die Datenquelle **Prometheus** auswaehlen
5. Auf **Import** klicken

Das Dashboard zeigt Pods, Container-Status, Restarts und Ressourcen
in einer uebersichtlichen Ansicht.

### Weitere empfehlenswerte Dashboard-IDs

| ID | Name | Zeigt |
|----|------|-------|
| 15760 | Kubernetes Views - Pods | Pod-Status, Restarts, Ressourcen |
| 15757 | Kubernetes Views - Global | Cluster-Gesamtuebersicht |
| 15758 | Kubernetes Views - Namespaces | Ressourcen pro Namespace |
| 15761 | Kubernetes Views - Nodes | Node-Metriken detailliert |

Alle findest du auf: https://grafana.com/grafana/dashboards/

## Schritt 3: Panel selbst bauen

Eigene Panels sind nuetzlich wenn man spezifische Metriken im Blick
behalten will — zum Beispiel aus einer eigenen App.

### Neues Dashboard anlegen

1. **Dashboards** → **New** → **New dashboard** klicken
2. **Add visualization** klicken
3. Als Datenquelle **Prometheus** auswaehlen

### Panel 1: CPU-Auslastung pro Node

Im Query-Feld eingeben:

```
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

Rechts unter **Panel options** einen Titel vergeben:

```
CPU-Auslastung pro Node (%)
```

Unter **Standard options** → **Unit** auf `Percent (0-100)` setzen.

Oben rechts **Apply** klicken.

### Panel 2: RAM-Verbrauch pro Node in GB

**Add** → **Visualization** klicken, dann:

```
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / 1024 / 1024 / 1024
```

Titel: `RAM-Verbrauch pro Node (GB)` — Unit: `gigabytes`

**Apply** klicken.

### Panel 3: Anzahl laufender Pods pro Namespace

```
count by (namespace) (kube_pod_info)
```

Rechts den Visualisierungstyp auf **Bar chart** umstellen.

Titel: `Pods pro Namespace`

**Apply** klicken.

### Dashboard speichern

Oben rechts auf das **Speichern-Symbol** (Diskette) klicken,
Namen vergeben z.B. `Mein Kubernetes Dashboard`, dann **Save**.

## Schritt 4: Zeitraum und Auto-Refresh einstellen

Oben rechts im Dashboard:

- **Zeitraum** (z.B. `Last 1 hour`) auf `Last 15 minutes` aendern
- **Auto-refresh** auf `10s` einstellen → Dashboards aktualisieren sich automatisch

## Schritt 5: Panel anpassen (optional)

Ein bestehendes Panel bearbeiten:

1. Auf einen Panel-Titel klicken → **Edit** waehlen
2. Query aendern oder zweite Query hinzufuegen (**+ Add query**)
3. Unter **Legend** einen sinnvollen Anzeigenamen eintragen,
   z.B. `{{instance}}` fuer den Node-Namen aus dem Label
4. **Apply** → **Save**

## Referenzen

  * https://grafana.com/grafana/dashboards/
  * https://grafana.com/grafana/dashboards/15760-kubernetes-views-pods/
  * https://0xdc.me/blog/a-set-of-modern-grafana-dashboards-for-kubernetes/
  * https://github.com/dotdc/grafana-dashboards-kubernetes?tab=readme-ov-file#install-via-grafanacom
