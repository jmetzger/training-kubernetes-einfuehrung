
# CheckMK Edition Enterprise / Cloud - Kubernetes Monitoring einrichten

   * Wir verwenden im Training die Edition Cloud (weil diese eine 30-Tage Trial-Version bietet)

## Hintergrund

CheckMK kann Kubernetes-Cluster ueber die Kubernetes API monitoren. Die Integration besteht aus:

| Komponente | Funktion | Deployment |
|------------|----------|------------|
| **Cluster Collector** | Sammelt Metriken aus dem Cluster (CPU, RAM, Netzwerk) | Helm Chart in K8s |
| **Node Collector** | Laeuft auf jedem Node, sammelt Ressourcen-Auslastung | DaemonSet via Helm |
| **Kubernetes Special Agent** | Fragt K8s API ab (Pods, Services, Deployments, etc.) | Laeuft auf CheckMK Server |
| **Piggyback Hosts** | Virtuelle Hosts fuer K8s Objekte in CheckMK | Manuell in CheckMK RAW |

**Wichtig:** CheckMK RAW erfordert manuelle Erstellung der Piggyback-Hosts (in kommerziellen Editionen (Enterprise und Cloud) automatisch).

**Diese Anleitung verwendet:**
- **Ingress (Traefik) mit HTTPS/TLS** statt NodePort
- **Let's Encrypt** für automatische SSL-Zertifikate via cert-manager
- **ClusterIP Service** für internen Zugriff

## Voraussetzungen

- Zugang zum Kubernetes Cluster mit kubectl
- CheckMK RAW Site: `https://checkmk-tln<X>.do.t3isp.de/` (X = Teilnehmer-Nummer)
- Helm installiert
- **cert-manager installiert** (siehe `ingress/https-letsencrypt-ingress-traefik.md`)
- **ClusterIssuer `letsencrypt-prod` konfiguriert**
- **Traefik Ingress Controller** installiert und funktionsfähig

## Schritt 1: Helm Repository hinzufuegen

```
helm repo add checkmk-chart https://checkmk.github.io/checkmk_kube_agent
helm repo update
```

Verfuegbare Versionen anzeigen:

```
helm search repo checkmk-chart --versions | head -10
```

## Schritt 2: Cluster Collector deployen (mit Ingress) 

Standard-Konfiguration anzeigen:

```
helm show values checkmk-chart/checkmk > ~/checkmk-values.yaml
```

Values für ingress setzen 

```
cd
mkdir -p helm-charts/checkmk
cd helm-charts/checkmk
nano values.yaml
```

**Wichtig:** Ersetze `<X>` mit deiner Teilnehmer-Nummer!

```
clusterCollector:
  ingress:
    enabled: true
    className: traefik
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - host: checkmk-collector.tln<X>.do.t3isp.de
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
        - checkmk-collector.tln<X>.do.t3isp.de
        secretName: checkmk-collector-tls
```


Helm Chart installieren:

```
helm upgrade --install checkmk checkmk-chart/checkmk \
  --namespace checkmk-monitoring \
  --create-namespace \
  --version 1.9.0 \
  --reset-values \
  -f values.yaml 
```

**Erklärung der Flags:**
- `--create-namespace`: Erstellt den Namespace automatisch (kein `kubectl create namespace` nötig)
- `--version 1.9.0`: Verwendet spezifische Chart-Version (reproduzierbar)
- `--reset-values`: Stellt sicher, dass keine alten Values übernommen werden
- `-f values.yaml`: Konfigurationswerte aus values.yaml verwenden (für ingress.yaml)

## Schritt 3: Deployment pruefen

```
kubectl get pods -n checkmk-monitoring
kubectl get svc -n checkmk-monitoring
kubectl get daemonset -n checkmk-monitoring
```

Erwartete Pods:
- `checkmk-cluster-collector-*` - 1 Pod
- `checkmk-node-collector-*` - 1 Pod pro Node (DaemonSet)




## Schritt 4: Zertifikat prüfen 

Zertifikat pruefen:

```
kubectl get certificate -n checkmk-monitoring
kubectl get secret checkmk-collector-tls -n checkmk-monitoring
```

**Voraussetzung:** cert-manager muss installiert sein und der ClusterIssuer `letsencrypt-prod` muss existieren (siehe `ingress/https-letsencrypt-ingress-traefik.md`).

## Schritt 5: Service Account Token extrahieren

Der ServiceAccount wurde automatisch vom Helm Chart erstellt. Token extrahieren:

```
# Secret-Name finden
kubectl get secrets -n checkmk-monitoring | grep checkmk

# Token extrahieren und dekodieren
kubectl get secret checkmk-checkmk -n checkmk-monitoring -o jsonpath='{.data.token}' | base64 --decode > sa-token
```

**Wichtig:** Token speichern - wird fuer CheckMK benoetigt!

Alternative (wenn kein Secret existiert):

```
# Token direkt vom ServiceAccount holen
kubectl create token checkmk -n checkmk-monitoring --duration=87600h
```

## Schritt 6: CA-Zertifikat extrahieren

```
kubectl config view 
# [1] weil 1. Cluster digitalocean, index 0
# Wenn nur 1 Eintrag, dann [0]

# Testen, ob ich so ein Zertifikat sehe 
kubectl config view --raw -o jsonpath='{.clusters[1].cluster.certificate-authority-data}' | base64 --decode 
```

<img width="1160" height="694" alt="image" src="https://github.com/user-attachments/assets/85e14f69-a728-4a40-bab7-88a435a23a80" />

```
# Abspeichern
kubectl config view --raw -o jsonpath='{.clusters[1].cluster.certificate-authority-data}' | base64 --decode > k8s-ca.crt
```

CA-Zertifikat anzeigen:

```
cat k8s-ca.crt
# und prüfen ob es das richtige ist:
# muss kubernetes heissen 
openssl x509 -in k8s-ca.crt -issuer -noout
```

## Schritt 7: Cluster Collector Endpoint ermitteln

Ingress-URL verwenden:

```
kubectl get ingress -n checkmk-monitoring
```

Der Cluster Collector Endpoint ist:

```
https://checkmk-collector.tln<X>.do.t3isp.de
```

**Wichtig:**
- Ersetze `<X>` mit deiner Teilnehmer-Nummer
- HTTPS wird durch Let's Encrypt bereitgestellt
- Der Endpoint ist von aussen erreichbar

Testen (sollte Not authorized zurueckgeben):

```
curl https://checkmk-collector.tln<X>.do.t3isp.de
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
6. 1 Changes (oben rechts anklicken)
7. **Activate on selected sites**

## Schritt 9: CA-Zertifikat in CheckMK importieren

1. **Setup > General > Global settings > Site management (Ausklappen) **
2. Suche nach **"Trusted certificate authorities for SSL"** -> Rechts in das Feld mit allen Zertifikateinträgen klicken
3. ** Add new CA certificate or chain **
4. Fuege den Inhalt von `k8s-ca.crt` hinzu
5. **Save**
6. 1 change (oben rechts) anklicken
7. Activate on selected sites 

## Schritt 10: Piggyback Host erstellen

1. **Setup > Hosts > Add host**
2. Konfiguration:
   - **Hostname:** `k8s-cluster-<dein-name>` (z.B. `k8s-cluster-jmetzger`)
   - **IP address family:** -> anklicken, dann im Select **No IP** (wichtig!)
   - **Monitoring agents:** -> Zeile: Checkmk agent /API integrations -> anklicken -> <img width="340" height="39" alt="image" src="https://github.com/user-attachments/assets/9ffd4b87-993a-4b8d-b098-58609ab2f0ba" />
   - ** Custom attributes ausklappen ** -> dort
   - Labels hinzufuegen:
     - `cmk/kubernetes`:yes
3. **Save & view folder ** (NICHT "Save & run service discovery")
4. 1 change anklicken
5. **Activate on selected sites**

**Wichtig:** Der Host bekommt keine IP, da er nur Piggyback-Daten empfaengt!

## Schritt 11: Ordner für Dynamic Host Management einrichten 

   * Wir brauchen nur den Ordner erstellen, sonst nichts. Alles was man dort eintragen kann, sind defaults die sich dann auf die Host vererben. 

1. Setup > Hosts > Add folder (in which the dynamic host management can automatically create all hosts of a cluster. However, creating or using such a folder is optional)
2. Title: z.B. k8s-cluster-jmetzger-data
3. **Save**
4. 1 change anklicken
5. **Activate on selected sites**

## Schritt 12: Dynamic Host Management einrichten 

 1. Setup > Hosts > Dynamic host management > Add connection
 2. Unique ID und Title eintragen

<img width="828" height="322" alt="image" src="https://github.com/user-attachments/assets/b41fd0ff-0a0c-47f6-8aa3-d3eade8e666c" />

 3. Bei **Create Hosts in** den gerade erstellten Ordner aus 11 angeben

 <img width="1465" height="296" alt="image" src="https://github.com/user-attachments/assets/46c1a8ac-802d-4014-89ac-fd7331a15107" />

 4. Hosts attributes können wir so lassen (es wird nur piggyback data erstellt)
 5. Setze einen Haken bei

<img width="574" height="78" alt="image" src="https://github.com/user-attachments/assets/63066d21-1de1-49df-a712-72d0b2873543" />

  6. (Bei Restrict Source (ganz oben), den erstellten piggyback host auwählen (aus 10.) z.B. k8s-cluster-jmetzger

<img width="462" height="126" alt="image" src="https://github.com/user-attachments/assets/100698ed-3faf-4461-8db3-e35811e4dfe7" />

  7. Service Discovery -> Discover Services During Creation -> Ankreuzen (falls nicht bereits aktiv) 

<img width="331" height="68" alt="image" src="https://github.com/user-attachments/assets/1175ce4c-e3b8-477b-aba3-6666ed536579" />

  8. Save
  9. **1 Change** anklicken
  10. **Activate on selected site**

## Schritt 13: Kubernetes Special Agent konfigurieren

1. **Setup > Agents > VM, cloud, container > Kubernetes**
2. Klicke **Add rule**
3. **Kubernetes cluster configuration:**
   - **Cluster name:** `k8s-cluster-<dein-name>` (oder eigener Name)
   - **Token:** Waehle `k8s-token` aus Dropdown
   - **API server endpoint:** `https://<DEINE-K8S-API-IP>:6443`
   - **SSL certificate verification:** Enabled (mit importiertem CA-Cert)

4. **Collector: Enrich With Usage Data**
   - **Cluster collector endpoint:** `https://checkmk-collector.tln<X>.do.t3isp.de` (Achtung https vorner ist wichtig)

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
   - **Include namespaces:** Leer lassen fuer alle Namespaces
   - **Exclude namespaces:** `kube-public,kube-node-lease` (optional)

   **Hinweise:**
   - `kube-system` wird inkludiert um System-Komponenten zu monitoren. `kube-public` und `kube-node-lease` sind meist leer bzw. nicht relevant fuer Monitoring.
   - **Filter-Logik:** Include wird zuerst angewendet (leer = alle), danach Exclude. **Exclude hat immer Vorrang** - ein Namespace in beiden Listen wird ausgeschlossen.

7. **Explicit hosts:**
   - Waehle `k8s-cluster-<dein-name>` (Host aus Schritt 10)

8. **Save**

9. Oben rechts auf **"1 change"** (oder mehr) klicken
10. **Activate on selected sites**
11. Warten bis Aktivierung abgeschlossen

## Schritt 14: Service Discovery durchfuehren

1. **Setup > Hosts**
2. Suche Host `k8s-cluster-<dein-name>`
3. Klicke auf Host
4. **Run service discovery** (Das ist eines der Symbole - gelber Kasten) <img width="36" height="34" alt="image" src="https://github.com/user-attachments/assets/9324179f-ec1c-40ca-9026-c0d428819761" />

Erwartete Services:
- `Kubernetes Cluster CPU resources`
- `Kubernetes Cluster Memory resources`
- `Kubernetes Node <node-name>`
- Weitere Services je nach Objekt-Auswahl

  5. Nach dem finden der Services dieses übernehmen 

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
# Ingress pruefen
kubectl get ingress -n checkmk-monitoring
kubectl describe ingress checkmk-collector-ingress -n checkmk-monitoring

# Service pruefen
kubectl get svc -n checkmk-monitoring

# Testen von lokalem Rechner
curl https://checkmk-collector-tln<X>.app.do.t3isp.de/openmetrics

# Zertifikat pruefen (sollte Ready: True sein)
kubectl get certificate -n checkmk-monitoring
```

### Problem: Unauthorized bei API-Zugriff

**Loesung:**
```
# Token-Gueltigkeit pruefen
kubectl get secrets -n checkmk-monitoring

# Neues Token erstellen
kubectl create token checkmk -n checkmk-monitoring --duration=87600h
```

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
| Cluster Collector | Deployed via Helm (ClusterIP Service) |
| Ingress | Traefik mit TLS/Let's Encrypt |
| Node Collector | DaemonSet auf allen Nodes |
| K8s Special Agent | Konfiguriert in CheckMK |
| Piggyback Host | Manuell erstellt (RAW) |
| Service Discovery | Durchgefuehrt |
| Monitoring | Aktiv via HTTPS |

## Weiterführende Informationen

Offizielle Dokumentation:
https://docs.checkmk.com/latest/en/monitoring_kubernetes.html
