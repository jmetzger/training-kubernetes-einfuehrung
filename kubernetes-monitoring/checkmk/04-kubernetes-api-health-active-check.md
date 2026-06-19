# Kubernetes API Health als HTTP Active Check in Checkmk

## Hintergrund

Jeder Kubernetes-Cluster stellt drei Health-Endpunkte bereit, die **ohne Authentifizierung** erreichbar sind:

| Endpunkt | Inhalt | Antwort |
|----------|--------|---------|
| `/healthz` | Allgemeiner Cluster-Health | `ok` |
| `/livez`   | API-Server am Leben?      | `ok` |
| `/readyz`  | API-Server bereit?        | `ok` |

Diese Endpunkte sind in **jedem vanilla Kubernetes-Cluster** immer vorhanden –
kein Prometheus, kein extra Deployment noetig.

**Ziel:** Den `/healthz`-Endpunkt als **HTTP Active Check** in Checkmk einrichten.
Checkmk misst dann die Antwortzeit als Metrik und schlaegt Alarm,
wenn der Endpunkt nicht mehr erreichbar ist.

**Active Check vs. Passive Check:**

| Typ | Wo laeuft er? | Typische Plugins |
|-----|---------------|-----------------|
| Passive Check | Auf dem ueberwachten Host | CPU, RAM, Disk |
| **Active Check** | **Auf dem Checkmk-Server** | check_httpv2, check_tcp |

## Schritt 1: API-Server URL ermitteln

```
kubectl cluster-info
```

Erwartete Ausgabe:

```
Kubernetes control plane is running at https://<uuid>.k8s.ondigitalocean.com
```

Die URL notieren (ohne `/` am Ende) – sie wird in Schritt 3 benoetigt.

## Schritt 2: Endpunkt manuell testen

Vom Checkmk-Server aus (z.B. via SSH oder im Docker-Container):

```
curl -sk https://<uuid>.k8s.ondigitalocean.com/healthz
```

Erwartete Ausgabe:

```
ok
```

HTTP 200 + `ok` = API-Server gesund. Der Parameter `-k` ist noetig, weil
DigitalOcean Managed Kubernetes ein eigenes CA-Zertifikat verwendet.

## Schritt 3: Active Check in Checkmk einrichten (GUI)

1. **Setup** aufrufen → oben in der Suchleiste `HTTP` eintippen

2. **"Check HTTP web service"** auswaehlen

   > Hinweis: Es gibt noch das aeltere "Check HTTP service (deprecated)".
   > Bitte das **neue** ohne "(deprecated)" verwenden.

3. **"Add rule"** klicken

4. Einstellungen befuellen:

   **Abschnitt "General properties":**
   - Description: `Kubernetes API Health Check`

   **Abschnitt "Check HTTP web service" → "HTTP web service endpoints to monitor"** → `Add entry`:
   - **Service name → Name**: `Kubernetes API Health`
   - **Service name → Prefix**: `Use "HTTP(S)" as service name prefix` (Standard)
   - **URL**: `https://<uuid>.k8s.ondigitalocean.com/healthz`

   Weiter unten im gleichen Entry-Bereich oder unter **"Standard settings for all endpoints"**:
   - **Certificate validity**: `Ignore certificate` auswaehlen

   Optional (fuer Inhaltspruefung):
   - **Search for strings → Search in body**: `ok` eintragen

5. **Abschnitt "Conditions":**
   - **Explicit hosts**: `k8s-cluster-<dein-name>` eintragen
     (z.B. `k8s-cluster-tln1` fuer Teilnehmer 1)

6. **Save** klicken

## Schritt 4: Changes aktivieren und Service Discovery

```
# Im Checkmk-Menue oben rechts:
# "Activate pending changes" klicken (gelbes Banner)
```

Danach unter **Monitoring → Hosts → k8s-cluster-<dein-name>**:
- **"Service discovery"** aufrufen
- Den neuen Service `HTTPS Kubernetes API Health` auf **"Monitor"** setzen
- Erneut **"Activate pending changes"**

## Ergebnis

Nach der Aktivierung erscheint der Service in der Host-Ansicht:

```
HTTPS Kubernetes API Health    OK    Version: HTTP/2.0, Status: 200 OK
```

Die **Metriken** des Services:

| Metrik | Beispielwert | Bedeutung |
|--------|-------------|-----------|
| `response_time` | 0.031s | Gesamte Antwortzeit |
| `time_http_headers` | 0.031s | Zeit bis Header empfangen |
| `time_http_body` | 0.0001s | Zeit fuer Body-Uebertragung |
| `response_size` | 2 B | Groesse der Antwort (`ok` = 2 Bytes) |

Auf den Service klicken → **"Service metrics"** zeigt die Antwortzeit als Zeitreihen-Graph.

## Schwellenwerte konfigurieren (optional)

In der gleichen Regel unter **"Standard settings for all endpoints"**:
- **Response time → Warn**: z.B. `1.0 s`
- **Response time → Crit**: z.B. `5.0 s`

## Was passiert bei einem Fehler?

| Situation | Checkmk-Status |
|-----------|---------------|
| HTTP 200 + Body `ok` | OK (gruen) |
| HTTP 200 + Body passt nicht | CRIT (rot) |
| HTTP != 200 | CRIT (rot) |
| Timeout / nicht erreichbar | CRIT (rot) |

## Aufraeumen

Die Regel wieder loeschen:

**Setup → Check HTTP web service** → Regel loeschen → Activate changes
