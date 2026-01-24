# CheckMK RAW - Kubernetes Monitoring einrichten

## Hintergrund

CheckMK kann Kubernetes-Cluster ueber die Kubernetes API monitoren. Die Integration besteht aus:

| Komponente | Funktion | Deployment |
|------------|----------|------------|
| **Cluster Collector** | Sammelt Metriken aus dem Cluster (CPU, RAM, Netzwerk) | Helm Chart in K8s |
| **Node Collector** | Laeuft auf jedem Node, sammelt Ressourcen-Auslastung | DaemonSet via Helm |
| **Kubernetes Special Agent** | Fragt K8s API ab (Pods, Services, Deployments, etc.) | Laeuft auf CheckMK Server |
| **Piggyback Hosts** | Virtuelle Hosts fuer K8s Objekte in CheckMK | Manuell in CheckMK RAW |

**Wichtig:** CheckMK RAW erfordert manuelle Erstellung der Piggyback-Hosts (in kommerziellen Editionen automatisch).

## Voraussetzungen

- Zugang zum Kubernetes Cluster mit kubectl
- CheckMK RAW Site: `https://checkmk-tln<X>.do.t3isp.de/` (X = Teilnehmer-Nummer)
- Helm installiert

## Schritt 1: Helm Repository hinzufuegen

```
helm repo add checkmk-chart https://checkmk.github.io/checkmk_kube_agent
helm repo update
```

Verfuegbare Versionen anzeigen:

```
helm search repo checkmk-chart --versions
```

## Schritt 2: Namespace erstellen

```
kubectl create namespace checkmk-monitoring
```

## Schritt 3: Cluster Collector deployen

Standard-Konfiguration anzeigen:

```
helm show values checkmk-chart/checkmk > /tmp/checkmk-values.yaml
```

Minimale Konfiguration fuer NodePort erstellen:

```
cd
mkdir -p manifests/checkmk
cd manifests/checkmk
```

```
# vi values.yaml
clusterCollector:
  service:
    type: NodePort
    nodePort: 30035
```

Helm Chart installieren:

```
helm upgrade --install checkmk checkmk-chart/checkmk \
  -n checkmk-monitoring \
  -f values.yaml
```

## Schritt 4: Deployment pruefen

```
kubectl get pods -n checkmk-monitoring
kubectl get svc -n checkmk-monitoring
kubectl get daemonset -n checkmk-monitoring
```

Erwartete Pods:
- `checkmk-cluster-collector-*` - 1 Pod
- `checkmk-node-collector-*` - 1 Pod pro Node (DaemonSet)

## Schritt 5: Service Account Token extrahieren

Der ServiceAccount wurde automatisch vom Helm Chart erstellt. Token extrahieren:

```
# Secret-Name finden
kubectl get secrets -n checkmk-monitoring | grep checkmk

# Token extrahieren und dekodieren
kubectl get secret <secret-name> -n checkmk-monitoring -o jsonpath='{.data.token}' | base64 --decode
```

**Wichtig:** Token speichern - wird fuer CheckMK benoetigt!

Alternative (wenn kein Secret existiert):

```
# Token direkt vom ServiceAccount holen
kubectl create token checkmk -n checkmk-monitoring --duration=87600h
```

## Schritt 6: CA-Zertifikat extrahieren

```
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode > /tmp/k8s-ca.crt
```

CA-Zertifikat anzeigen:

```
cat /tmp/k8s-ca.crt
```

## Schritt 7: Cluster Collector Endpoint ermitteln

NodePort-Service finden:

```
kubectl get svc -n checkmk-monitoring checkmk-cluster-collector
```

Cluster IP und NodePort anzeigen. Der Endpoint ist:

```
http://<DEINE-K8S-NODE-IP>:30035
```

**Tipp:** Deine K8s Node IP findest du mit:

```
kubectl get nodes -o wide
```

## Schritt 8: CheckMK konfigurieren - Token speichern

1. Oeffne CheckMK: `https://checkmk-tln<X>.do.t3isp.de/`
2. Gehe zu **Setup > General > Passwords**
3. Klicke **Add password**
4. Konfiguration:
   - **Unique ID:** `k8s-token`
   - **Title:** `Kubernetes Service Account Token`
   - **Password:** Token aus Schritt 5 einfuegen
5. **Save**

## Schritt 9: CA-Zertifikat in CheckMK importieren

1. **Setup > Global settings > Site management**
2. Suche nach **"Trusted certificate authorities for SSL"**
3. Fuege den Inhalt von `/tmp/k8s-ca.crt` hinzu
4. **Save**

## Schritt 10: Piggyback Host erstellen

1. **Setup > Hosts > Add host**
2. Konfiguration:
   - **Hostname:** `k8s-cluster-<dein-name>` (z.B. `k8s-cluster-jmetzger`)
   - **IP address family:** **No IP** (wichtig!)
   - **Monitoring agents:** Generic
   - Labels hinzufuegen:
     - Key: `cmk/kubernetes`
     - Value: `yes`
3. **Save & go to service configuration** (NICHT "Save & run service discovery")

**Wichtig:** Der Host bekommt keine IP, da er nur Piggyback-Daten empfaengt!

## Schritt 11: Kubernetes Special Agent konfigurieren

1. **Setup > Agents > VM, cloud, container > Kubernetes**
2. Klicke **Add rule**
3. **Kubernetes cluster configuration:**
   - **Cluster name:** `mycluster` (oder eigener Name)
   - **Token:** Waehle `k8s-token` aus Dropdown
   - **API server endpoint:** `https://<DEINE-K8S-API-IP>:443`
   - **SSL certificate verification:** Enabled (mit importiertem CA-Cert)

4. **Collector configuration:**
   - **Cluster collector endpoint:** `http://<DEINE-K8S-NODE-IP>:30035`

5. **Kubernetes API:**
   - **Object selection:** Waehle gewuenschte Objekte:
     - ✓ Pods
     - ✓ Nodes
     - ✓ Deployments
     - ✓ DaemonSets
     - ✓ StatefulSets
     - ✓ Services
     - ✓ Namespaces
     - ✓ CronJobs (falls benoetigt)

6. **Namespace filtering:**
   - **Include namespaces:** Leer lassen fuer alle (oder spezifische Namespaces)
   - **Exclude namespaces:** `kube-system,kube-public,kube-node-lease` (optional)

7. **Explicit hosts:**
   - Waehle `k8s-cluster-<dein-name>` (Host aus Schritt 10)

8. **Save**

## Schritt 12: Aenderungen aktivieren

1. Oben rechts auf **"1 change"** (oder mehr) klicken
2. **Activate on selected sites**
3. Warten bis Aktivierung abgeschlossen

## Schritt 13: Service Discovery durchfuehren

1. **Setup > Hosts**
2. Suche Host `k8s-cluster-<dein-name>`
3. Klicke auf Host
4. **Run service discovery**
5. **Accept all**
6. **Activate changes**

Erwartete Services:
- `Kubernetes Cluster CPU resources`
- `Kubernetes Cluster Memory resources`
- `Kubernetes Node <node-name>`
- Weitere Services je nach Objekt-Auswahl

## Schritt 14: Piggyback Hosts fuer K8s Objekte erstellen (CheckMK RAW)

In CheckMK RAW werden Hosts fuer Kubernetes-Objekte NICHT automatisch erstellt. Manuelle Erstellung:

```
# Auf dem CheckMK Server (falls SSH-Zugang)
# Site-Kontext wechseln
OMD[site]> cmk-piggyback list orphans
```

Alternativ in CheckMK GUI:
1. **Setup > Hosts > Add host**
2. Fuer jedes K8s Objekt (Pod, Deployment, etc.) einen Host erstellen:
   - **Hostname:** Exakter Name aus Piggyback-Daten (z.B. `pod_nginx-deployment-xyz`)
   - **IP address family:** No IP
   - Label: `cmk/kubernetes: yes`
3. Service Discovery durchfuehren

**Tipp fuer CheckMK RAW:** Beginne mit wichtigen Objekten (Nodes, Deployments), nicht alle Pods einzeln.

## Schritt 15: Periodic Service Discovery konfigurieren (optional)

Automatische Discovery fuer neue Services:

1. **Setup > Periodic service discovery**
2. **Add rule**
3. **Conditions:**
   - **Host labels:** `cmk/kubernetes:yes`
4. **Service discovery:**
   - **Mode:** "Add unmonitored services and new host labels"
   - **Interval:** 15 Minuten (kuerzer als Standard)
5. **Save**

## Schritt 16: Monitoring testen

Services pruefen:

1. **Monitor > All hosts**
2. Filter: `cmk/kubernetes:yes`
3. Services pruefen - Status sollte OK sein

Dashboards (nur in kommerziellen Editionen):
- CheckMK RAW hat keine vordefinierten K8s Dashboards
- Manuell Views erstellen moeglich

## Troubleshooting

### Problem: Keine Services gefunden

**Loesung:**
```
# Piggyback-Daten pruefen (auf CheckMK Server)
OMD[site]> cmk-piggyback list
OMD[site]> cmk-piggyback show <hostname>
```

### Problem: Connection refused zum Cluster Collector

**Loesung:**
```
# NodePort pruefen
kubectl get svc -n checkmk-monitoring

# Testen von lokalem Rechner
curl http://<node-ip>:30035/openmetrics
```

### Problem: Unauthorized bei API-Zugriff

**Loesung:**
```
# Token-Gueltigkeit pruefen
kubectl get secrets -n checkmk-monitoring

# Neues Token erstellen
kubectl create token checkmk -n checkmk-monitoring --duration=87600h
```

### Problem: Piggyback Hosts erstellen in RAW zu aufwaendig

**Loesung:**
- Fokus auf wichtige Hosts (Nodes, kritische Deployments)
- Script zur automatischen Host-Erstellung schreiben
- Oder: Upgrade zu kommerzieller Edition erwägen

## Aufraeumen

Helm Release entfernen:

```
helm uninstall checkmk -n checkmk-monitoring
```

Namespace loeschen:

```
kubectl delete namespace checkmk-monitoring
```

In CheckMK:
1. Hosts loeschen: **Setup > Hosts**
2. Rule loeschen: **Setup > Agents > VM, cloud, container > Kubernetes**
3. Token loeschen: **Setup > General > Passwords**
4. **Activate changes**

## Zusammenfassung

| Komponente | Status |
|------------|--------|
| Cluster Collector | Deployed via Helm |
| Node Collector | DaemonSet auf allen Nodes |
| K8s Special Agent | Konfiguriert in CheckMK |
| Piggyback Host | Manuell erstellt (RAW) |
| Service Discovery | Durchgefuehrt |
| Monitoring | Aktiv |

**CheckMK RAW Besonderheiten:**
- ✓ Vollstaendige K8s API Integration
- ✓ Cluster Collector fuer Metriken
- ✗ Keine automatischen Piggyback Hosts
- ✗ Keine vorgefertigten Dashboards
- Manueller Aufwand hoeher als kommerzielle Editionen

## Weiterführende Informationen

Offizielle Dokumentation:
https://docs.checkmk.com/latest/en/monitoring_kubernetes.html
