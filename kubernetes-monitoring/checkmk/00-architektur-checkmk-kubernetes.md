# Architektur: Checkmk + Kubernetes

## Überblick: Komponenten

```mermaid
graph TB
    subgraph K8S["☸ Kubernetes Cluster"]
        direction TB
        K8SAPI["K8s API Server"]

        subgraph NODES["Nodes"]
            direction LR
            NC1["Node Collector\nNode 1"]
            NC2["Node Collector\nNode 2"]
            NC3["Node Collector\nNode 3"]
        end

        CC["Cluster Collector\n(Deployment)"]
        ING["Ingress\nTraefik + TLS/Let's Encrypt"]

        NC1 -->|"CPU/RAM/Net"| CC
        NC2 -->|"CPU/RAM/Net"| CC
        NC3 -->|"CPU/RAM/Net"| CC
        CC --> ING
    end

    subgraph CMK["🔍 Checkmk Server (Docker)"]
        direction TB
        SA["Kubernetes\nSpecial Agent"]
        PB["Piggyback Data\n(pro K8s-Objekt ein Host)"]
        DHM["Dynamic Host Management\n(auto create / delete)"]
        MON["Monitoring\nServices · Dashboards · Alerts"]

        SA --> PB
        PB --> DHM
        DHM --> MON
    end

    SA -->|"① K8s API\nServiceAccount Token + CA-Cert"| K8SAPI
    K8SAPI -->|"Pods · Services · Deployments\nNodes · DaemonSets · Namespaces"| SA
    SA -->|"② Usage Metrics\nHTTPS"| ING
    ING -->|"CPU/RAM/Netzwerk\npro Pod und Node"| SA
```

## Datenfluss im Detail

```mermaid
sequenceDiagram
    participant NC as Node Collector<br/>(DaemonSet)
    participant CC as Cluster Collector<br/>(Deployment)
    participant SA as Special Agent<br/>(auf Checkmk)
    participant API as Kubernetes API
    participant CMK as Checkmk Monitoring

    Note over NC,CC: Im Cluster – läuft kontinuierlich
    NC->>CC: Metriken: CPU · RAM · Netzwerk<br/>(alle Nodes via /openmetrics)

    Note over SA,CMK: Checkmk-seitig – pro Check-Intervall
    SA->>API: GET Pods / Services / Deployments /<br/>Nodes / DaemonSets / StatefulSets
    API-->>SA: Status · Labels · Events · Conditions

    SA->>CC: GET /openmetrics<br/>(via Ingress HTTPS)
    CC-->>SA: Enriched Metrics<br/>(CPU/RAM pro Pod + Node)

    SA->>CMK: Piggyback Data<br/>(1 Host pro K8s-Objekt)
    CMK->>CMK: Dynamic Host Management<br/>→ neue Hosts anlegen<br/>→ gelöschte Hosts entfernen
    CMK->>CMK: Service Discovery<br/>→ Services pro Host erkennen
```

## Was liefert wer?

| Komponente | Typ | Daten | Deployment |
|------------|-----|-------|------------|
| **Node Collector** | DaemonSet (1× pro Node) | CPU, RAM, Netzwerk, Filesystem pro Node | Helm Chart im Cluster |
| **Cluster Collector** | Deployment (1×) | Aggregierte Metriken, Endpoint für Special Agent | Helm Chart im Cluster |
| **Kubernetes Special Agent** | Prozess auf Checkmk | K8s-Objekte (Pods, Services, Deployments...) | Läuft auf Checkmk-Server |
| **Piggyback Host** | Virtueller Host in Checkmk | Monitoring-Daten eines K8s-Objekts | Wird von Dynamic Host Mgmt erstellt |
| **Dynamic Host Management** | Checkmk-Feature | Erstellt/löscht Hosts für K8s-Objekte automatisch | Nur in Enterprise/Cloud Edition |

## Zwei Datenquellen des Special Agents

```mermaid
graph LR
    SA["Special Agent"]

    SA -->|"Quelle 1\nKubernetes API"| KAPI["K8s API Server\n:6443"]
    KAPI -->|"Struktur-Daten"| OBJ["Pods · Nodes · Services\nDeployments · Namespaces\nDaemonSets · StatefulSets"]

    SA -->|"Quelle 2\nCluster Collector"| CC["Cluster Collector\nhttps://checkmk-collector.tln1.do.t3isp.de"]
    CC -->|"Usage-Metriken"| MET["CPU-Nutzung pro Pod\nRAM-Nutzung pro Pod\nNetzwerk-Throughput\nFilesystem-Auslastung"]

    OBJ --> PB["Piggyback Data\n→ Checkmk-Hosts"]
    MET --> PB
```

## Piggyback-Konzept

Checkmk erstellt für jedes Kubernetes-Objekt einen **virtuellen Host** — den sogenannten **Piggyback Host**:

```mermaid
graph TB
    SA["Special Agent\nfragt K8s ab"] --> PB["Piggyback Data"]

    PB --> H1["Host: k8s-cluster-xyz"]
    PB --> H2["Host: pod/nginx-abc-123"]
    PB --> H3["Host: pod/mysql-def-456"]
    PB --> H4["Host: node/worker-1"]
    PB --> H5["Host: deployment/nginx"]
    PB --> H6["Host: namespace/production"]

    DHM["Dynamic Host Management\n(Enterprise/Cloud only)"] -->|"erstellt automatisch"| H2
    DHM -->|"erstellt automatisch"| H3
    DHM -->|"erstellt automatisch"| H4
    DHM -->|"löscht bei Wegfall"| H3
```

**Wichtig:** In der **RAW Edition** müssen Piggyback-Hosts manuell angelegt werden.  
In der **Enterprise/Cloud Edition** übernimmt das Dynamic Host Management dies automatisch.

## Netzwerk-Zugriffe (Checkmk → Cluster)

```mermaid
graph LR
    CMK["Checkmk Server\ntln1.do.t3isp.de"] -->|"HTTPS :443\nServiceAccount Token"| ING["Ingress\nTraefik"]
    CMK -->|"HTTPS :6443\nCA-Zertifikat + Token"| KAPI["K8s API Server"]

    ING -->|"intern"| CC["Cluster Collector\nClusterIP Service"]
    KAPI -->|"RBAC\nClusterRole"| SA_PERM["Lesezugriff auf\nPods · Nodes · Services..."]
```

## Weiterführende Dokumente

- Setup (Enterprise/Cloud): `setup-kubernetes-checkmk-enterprise-cloud-edition.md`
- Setup (RAW Edition): `setup-kubernetes-checkmk-raw.md`
- Enterprise-Features: `02-checkmk-kubernetes-wichtig-enterprise.md`
- Dashboards: `03-kubernetes-dashboards.md`
