# Strategie: Hochverfügbarkeit in Kubernetes-Clustern

**Kernprinzip:** Die Control Plane benötigt RTT < 10ms zwischen etcd-Nodes für stabilen Quorum-Betrieb. Workloads können über höhere Latenzen hinweg verteilt werden.

---
## Legende 

### RTO 

  * Recovery Time Objective
  * Die maximale akzeptable Zeit, bis ein System nach einem Ausfall wieder verfügbar sein muss.

### RPO 

  * Recovery Point Objective (häufig zusammen genannt)
  * Der maximale akzeptable Datenverlust, gemessen in Zeit.


## FALL 1: Single-Cluster in einem Rechenzentrum

### Ausgangssituation
- 3 Control Plane Nodes (stacked etcd)
- 1+n Worker Nodes
- Alle Nodes im selben RZ

### Sinnvoll wenn:
- RTO: 1-5 Minuten (Wie lange bis wieder verfügbar)
- RPO: Nahe Null (bei korrekter Storage-Konfiguration)
- Budget: Gering bis mittel
- Keine regulatorischen Anforderungen für Geo-Redundanz
- Primäres Ziel: Schutz vor Hardware-/Software-Ausfällen

### HA-Strategie Control Plane

**etcd-Cluster (3 Nodes)**
```yaml
# Unbedingt odd number: 3 oder 5 nodes
# 3 Nodes tolerieren 1 Ausfall
# 5 Nodes tolerieren 2 Ausfälle
```
- Separate Hosts für etcd (empfohlen) oder stacked etcd
- Separate Disks mit niedriger Latenz (NVMe SSD)
- Monitoring: etcd-Metriken (Leader Elections, DB Size)
- Backup-Strategie: Regelmäßige etcd-Snapshots

**API Server Load Balancing**
- Redundante kube-apiserver auf allen Control Plane Nodes
- Virtual IP (VIP) oder Hardware Load Balancer vor API Servers
- Tools: kube-vip, HAProxy, keepalived

**Scheduler & Controller Manager**
- Laufen auf allen Control Plane Nodes
- Leader Election über Leases in kube-system
- Automatisches Failover bei Node-Ausfall

### HA-Strategie Workload

**Pod-Replikation**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3  # Minimum für HA
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web-app
```

**PodDisruptionBudgets (PDB)**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web-app
```

**Anti-Affinity Rules**
- Pods auf unterschiedliche Worker Nodes verteilen
- `requiredDuringSchedulingIgnoredDuringExecution` für strikte Trennung

### Storage HA

**Lokale Storage-Lösungen:**
- Rook-Ceph: Distributed Storage mit Replikation
- Longhorn: Leichtgewichtige Alternative (schlechte Performance)
- OpenEBS: Verschiedene Storage Engines (nur readwriteonce)

**Externe Storage:**
- NFS mit HA (z.B. über DRBD)
- iSCSI mit Multipathing (nur readwriteonce)
- Cloud-Provider CSI-Driver (bei Managed Kubernetes)

**Backup:**
- Velero für Cluster-Backups
- Regelmäßige Application-Level Backups
- Externe Backup-Location (S3-kompatibel)

### Netzwerk HA

**CNI-Redundanz:**
- Calico, Cilium oder Flannel mit HA-Konfiguration
- Redundante Netzwerk-Interfaces auf Nodes

**Load Balancer:**
- MetalLB für Bare-Metal (Layer 2 oder BGP-Mode)
- Cloud-Provider Load Balancer (bei Managed Services)

**Ingress HA:**
```yaml
# Nginx Ingress mit mindestens 2 Replicas
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --set controller.replicaCount=3 \
  --set controller.service.externalTrafficPolicy=Local
```

### Single Points of Failure (SPOFs)

| Komponente | Risiko | Mitigation |
|------------|--------|-----------|
| Load Balancer vor API Server | Hoch | kube-vip mit VRRP oder redundante Hardware-LB |
| Storage Backend | Hoch | Distributed Storage (Ceph, Longhorn) |
| Gesamtes RZ | Hoch | Nur durch Multi-RZ-Setup adressierbar |

### Tools & Komponenten

- **kube-vip**: VIP für API Server (Layer 2 oder BGP)
- **HAProxy/keepalived**: Alternative zu kube-vip
- **MetalLB**: Load Balancer für Bare-Metal
- **Velero**: Backup und Restore
- **Prometheus + Alertmanager**: Monitoring
- **etcdctl**: etcd-Management und Backups

### Vor-/Nachteile

**Vorteile:**
- Einfachste HA-Lösung
- Niedrige Latenz innerhalb Cluster
- Geringste Komplexität
- Moderate Kosten

**Nachteile:**
- Kein Schutz vor RZ-Ausfall
- Limitierte geografische Redundanz

### Kostenabschätzung
- **Relativ:** Basis (1x)
- **Absolute Kosten:** 3 Control Plane + 3+ Worker Nodes + Storage

### RTO/RPO
- **RTO:** 1-5 Minuten (bei automatischem Pod-Failover)
- **RPO:** < 1 Minute (bei korrekter Storage-Replikation)

### Quellen
- [Kubernetes HA Topologies](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/)
- [etcd Administration Guide](https://etcd.io/docs/v3.5/op-guide/)
- [kube-vip Documentation](https://kube-vip.io/)

---

## FALL 2: Multi-Zone Cluster (RTT < 10ms)

### Ausgangssituation
- 3-5 Control Plane Nodes über Availability Zones verteilt
- Worker Nodes in allen Zones
- RTT zwischen Zones: < 10ms (typisch < 2ms innerhalb Region)
- Cloud-Provider oder Metro-RZ mit dedizierten Zonen

### Sinnvoll wenn:
- RTO: < 1 Minute
- RPO: Nahe Null
- Budget: Mittel
- Cloud-Native Deployment (AWS, GCP, Azure)
- Schutz gegen Zone-Ausfall erforderlich
- Keine strengen Latenzanforderungen zwischen Zones

### HA-Strategie Control Plane

**etcd über Zones verteilt**
- **Kritisch:** RTT muss < 10ms bleiben für etcd-Quorum
- Mindestens 3 Zones mit jeweils 1 Control Plane Node
- Bei 5 Nodes: 2-2-1 oder 2-1-2 Distribution

**Latenz-Monitoring:**
```bash
# etcd Performance-Check
etcdctl check perf --load="s"
# Warn bei > 10ms Backend Commit Duration
```

### HA-Strategie Workload

**Topology Spread Constraints**
```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web-app
      - maxSkew: 2
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
```

**Zone-Aware PodDisruptionBudgets**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
spec:
  minAvailable: 4  # Bei 6 Replicas über 3 Zones
  selector:
    matchLabels:
      app: web-app
  unhealthyPodEvictionPolicy: AlwaysAllow
```

### Storage HA

**Zone-Aware Storage Classes**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: zone-redundant
provisioner: kubernetes.io/aws-ebs  # Beispiel AWS
parameters:
  type: gp3
  iops: "3000"
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - eu-central-1a
    - eu-central-1b
    - eu-central-1c
```

**Replizierte Storage-Lösungen:**
- Rook-Ceph mit Zone-Awareness
- Portworx mit Zone-Replication
- Cloud-Provider replizierte Volumes

### Cloud-Provider Integration

**AWS:**
- EKS mit Multi-AZ Control Plane (Managed)
- EBS Multi-Attach für Shared Storage
- ELB/ALB automatisch über Zones verteilt

**GCP:**
- GKE Regional Clusters (Multi-Zonal Control Plane)
- Regional Persistent Disks
- Cloud Load Balancer über Zones

**Azure:**
- AKS mit Availability Zones
- Zone-Redundant Storage (ZRS)
- Azure Load Balancer Standard (Zone-Redundant)

### Tools & Komponenten

- **Cloud-Provider CCM**: Automatische Zone-Awareness
- **CSI-Driver**: Zone-Aware Storage Provisioning
- **Cluster Autoscaler**: Zone-Aware Scaling
- **Velero**: Multi-Zone Backups

### Vor-/Nachteile

**Vorteile:**
- Schutz gegen Zone-Ausfall
- Automatisches Failover
- Native Cloud-Integration
- Transparenz für Workloads

**Nachteile:**
- Höhere Cloud-Kosten (Cross-Zone Traffic)
- Potenzielle Latenz zwischen Zones
- Abhängigkeit von Cloud-Provider

### Kostenabschätzung
- **Relativ:** 1.5-2x (wegen Cross-Zone Traffic)
- **Zusatzkosten:** Data Transfer zwischen Zones (~0.01-0.02 €/GB)

### RTO/RPO
- **RTO:** < 1 Minute (automatisches Failover)
- **RPO:** 0 (synchrone Replikation)

### Quellen
- [Kubernetes Zone-Aware Scheduling](https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [GCP GKE Multi-Zonal Clusters](https://cloud.google.com/kubernetes-engine/docs/concepts/types-of-clusters)

---

## FALL 3: Stretched Cluster über RZ (RTT < 10ms)

### Ausgangssituation
- 2-3 physisch getrennte Rechenzentren
- RTT zwischen RZ: < 10ms (Metro-Cluster Szenario)
- Dedizierte Glasfaser-Verbindung zwischen RZ
- Geografische Distanz: typisch < 50-100 km

### Sinnvoll wenn:
- RTO: < 1 Minute
- RPO: Nahe Null
- Budget: Hoch
- Regulatorische Anforderungen für Geo-Redundanz
- Synchrone Daten-Replikation erforderlich
- Sehr niedrige Latenz zwischen RZ verfügbar

### HA-Strategie Control Plane

**Stretched etcd-Cluster mit Witness**
```
RZ1: 2 etcd Nodes
RZ2: 2 etcd Nodes
RZ3 (optional): 1 Witness Node

Total: 5 Nodes für 2-Node Ausfall-Toleranz
```

**Kritische Anforderungen:**
- RTT zwischen allen etcd-Nodes: < 10ms
- Stabile, dedizierte Netzwerk-Verbindung
- Monitoring für Network Partitions

**Split-Brain Prevention:**
- Odd number of etcd nodes
- Optional: Witness-Node in drittem Standort
- Fencing-Mechanismen auf Storage-Level

### HA-Strategie Workload

**Site-Aware Scheduling**
```yaml
apiVersion: v1
kind: Node
metadata:
  labels:
    topology.kubernetes.io/region: eu-central
    topology.kubernetes.io/zone: fra1  # RZ1
    site: primary
---
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: site
        whenUnsatisfiable: DoNotSchedule
```

### Storage-Replikation zwischen RZ

**Synchrone Replikation:**
- **Rook-Ceph** mit stretched cluster mode
  - Min. 5 OSD Nodes (2-2-1 über Sites)
  - Replicated Pools mit site-awareness
  
- **Portworx** mit DR-License
  - Synchronous Replication zwischen Sites
  - Automatic Failover

- **DRBD** für Block-Storage
  - Kernel-Level Replication
  - Dual-Primary Mode möglich

**Beispiel Ceph CRD:**
```yaml
apiVersion: ceph.rook.io/v1
kind: CephCluster
metadata:
  name: rook-ceph
spec:
  mon:
    count: 5
    allowMultiplePerNode: false
    volumeClaimTemplate:
      spec:
        storageClassName: local-storage
  placement:
    mon:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: site
              operator: In
              values:
              - site1
              - site2
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: site
```

### Netzwerk-Design

**Anforderungen:**
- Dedizierte Layer 2/3 Verbindung zwischen RZ
- BGP-Routing für Pod-Network
- Redundante Uplinks (LACP)

**CNI-Empfehlungen:**
- **Calico** mit BGP zwischen Sites
- **Cilium** mit Cluster Mesh (single cluster mode)

### Risiken & Mitigationen

| Risiko | Impact | Mitigation |
|--------|--------|-----------|
| Network Partition | Kritisch | Witness Node, Fencing |
| Latenz-Spikes | Hoch | SLA für Interconnect, Monitoring |
| Split-Brain Storage | Kritisch | Quorum-basierte Systeme |
| Asynchroner etcd | Kritisch | Automatisches Health-Check, Rollback |

### Tools & Komponenten

- **Rook-Ceph**: Distributed Storage
- **Portworx**: Enterprise Storage mit DR
- **DRBD**: Block-Level Replication
- **Cilium/Calico**: Advanced Networking
- **Disaster Recovery Tools**: Velero mit Multi-Site Backups

### Vor-/Nachteile

**Vorteile:**
- Transparente RZ-Redundanz
- Ein logischer Cluster
- Niedrige RTT für Workloads
- Automatisches Failover

**Nachteile:**
- Sehr hohe Komplexität
- Abhängigkeit von stabiler, niedriger Latenz
- Risiko für Split-Brain
- Hohe Kosten für Interconnect
- Schwierige Fehlerdiagnose

### Kostenabschätzung
- **Relativ:** 3-4x (Infrastructure, Interconnect, Storage-Lizenz)
- **Zusatzkosten:** Dedizierte Glasfaser, HA-Storage-Lizenzen

### RTO/RPO
- **RTO:** < 1 Minute (bei korrekter Konfiguration)
- **RPO:** 0 (synchrone Replikation)

### Warnung
⚠️ **Stretched Clusters sind komplex und fehleranfällig.** Nur bei zwingenden Business-Anforderungen und entsprechender Expertise empfohlen. Multi-Cluster-Setups (Fall 4) sind oft die bessere Wahl.

### Quellen
- [etcd Latency Requirements](https://etcd.io/docs/v3.5/op-guide/hardware/)
- [Ceph Stretched Cluster Mode](https://docs.ceph.com/en/latest/rados/operations/stretch-mode/)
- [Portworx Disaster Recovery](https://docs.portworx.com/portworx-enterprise/operations/operate-kubernetes/disaster-recovery)

---

## FALL 4: Multi-Cluster (RTT > 10ms oder unabhängige RZ)

### Ausgangssituation
- Separate Kubernetes-Cluster pro RZ/Region
- RTT zwischen RZ: > 10ms (typisch 30-200ms)
- Geografisch verteilte Standorte
- Jeder Cluster ist unabhängig lauffähig

### Sinnvoll wenn:
- RTO: 1-10 Minuten (manuell) oder < 1 Minute (automatisch)
- RPO: Sekunden bis Minuten (je nach Replikation)
- Budget: Mittel bis hoch
- Geo-Redundanz über weite Distanzen
- Disaster Recovery Anforderung
- Latenz-Optimierung für User (Edge-Deployment)
- Regulatorische Anforderungen (Data Residency)

### Multi-Cluster Architektur-Patterns

#### 4.1 Active-Passive (Cold Standby)

**Setup:**
- Primary Cluster: Alle Workloads aktiv
- Secondary Cluster: Bereit, aber idle
- DNS-Failover zu Secondary bei Primary-Ausfall

**Komponenten:**
- **GitOps**: ArgoCD oder Flux auf beiden Clustern
- **Backup**: Velero für Disaster Recovery
- **DNS**: External-DNS oder GSLB

**Vor-/Nachteile:**
- ✅ Einfachste Multi-Cluster Lösung
- ✅ Niedrige Laufkosten
- ❌ RTO: 5-15 Minuten (manuelle Aktivierung)
- ❌ Secondary-Cluster ungenutzt

#### 4.2 Active-Active (Hot Standby)

**Setup:**
- Traffic auf beide Cluster verteilt (z.B. 50/50 oder Geo-basiert)
- Automatisches Failover bei Cluster-Ausfall

**Komponenten:**
- **Global Load Balancer**: AWS Route53, Cloudflare, F5 GTM
- **Service Mesh**: Istio Multi-Cluster oder Linkerd
- **Data Replication**: Anwendungsspezifisch oder DB-Level

**Traffic Distribution:**
```yaml
# Beispiel: External-DNS mit GeoDNS
apiVersion: v1
kind: Service
metadata:
  name: web-app
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
    external-dns.alpha.kubernetes.io/aws-geolocation-routing-policy: "eu-central-1"
spec:
  type: LoadBalancer
```

**Vor-/Nachteile:**
- ✅ RTO: < 1 Minute (automatisch)
- ✅ Optimale Resource-Nutzung
- ✅ Geo-Latenz-Optimierung
- ❌ Hohe Komplexität
- ❌ Daten-Konsistenz-Herausforderungen

### Multi-Cluster Networking

#### Submariner
- Open-Source Multi-Cluster Networking
- Direct Pod-to-Pod Communication
- Cross-Cluster Service Discovery

```bash
# Installation
subctl deploy-broker --kubeconfig cluster1-config
subctl join --kubeconfig cluster1-config broker-info.subm
subctl join --kubeconfig cluster2-config broker-info.subm

# Service Export
subctl export service web-app -n production
```

**Eigenschaften:**
- IPsec/WireGuard Tunnel zwischen Clustern
- Automatisches Route-Advertisement
- Unterstützt unterschiedliche CNIs

#### Cilium Cluster Mesh

**Setup:**
```bash
# Cluster 1
cilium clustermesh enable
cilium clustermesh connect --destination-context cluster2

# Shared Service
kubectl annotate service web-app io.cilium/shared-service="true"
```

**Eigenschaften:**
- Native Pod-to-Pod Communication ohne Tunnel
- Service Affinity (bevorzuge lokale Pods)
- eBPF-basiert, sehr performant

### Service Mesh für Multi-Cluster

#### Istio Multi-Cluster

**Modelle:**

1. **Multi-Primary**: Jeder Cluster hat eigene Control Plane
```bash
istioctl install --set values.global.meshID=mesh1 \
  --set values.global.multiCluster.clusterName=cluster1 \
  --set values.global.network=network1
```

2. **Primary-Remote**: Shared Control Plane
```bash
# Primary
istioctl install --set values.global.externalIstiod=true

# Remote
istioctl install --set profile=remote \
  --set values.global.remotePilotAddress=<primary-istiod-ip>
```

**Cross-Cluster Traffic:**
```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: web-app-cluster2
spec:
  hosts:
  - web-app.production.svc.cluster.local
  location: MESH_INTERNAL
  ports:
  - number: 80
    name: http
  resolution: DNS
  endpoints:
  - address: web-app.production.svc.cluster2.global
```

### Multi-Cluster GitOps

#### ArgoCD Multi-Cluster

**Setup:**
```bash
# Cluster registrieren
argocd cluster add cluster1-context
argocd cluster add cluster2-context

# ApplicationSet für beide Cluster
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: web-app
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          env: production
  template:
    spec:
      source:
        repoURL: https://github.com/org/repo
        path: apps/web-app
      destination:
        name: '{{name}}'
        namespace: production
```

**Strategien:**
- **Pull-Model**: Jeder Cluster hat eigenes ArgoCD
- **Push-Model**: Zentrales ArgoCD verwaltet alle Cluster

#### Flux Multi-Cluster

```yaml
# Flux Configuration per Cluster
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps
spec:
  interval: 5m
  path: ./clusters/cluster1
  prune: true
  sourceRef:
    kind: GitRepository
    name: fleet-infra
```

### Daten-Replikation Strategien

#### Anwendungsebene
- Application-Managed Replication (z.B. Kafka Multi-DC)
- Event Sourcing mit Cross-Cluster Event Streams
- CQRS mit regionalen Read-Replicas

#### Datenbank-Replikation

**PostgreSQL:**
```yaml
# CrunchyData Postgres Operator mit Standby
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
spec:
  instances:
  - name: instance1
    replicas: 3
    dataVolumeClaimSpec:
      accessModes:
      - ReadWriteOnce
  patroni:
    dynamicConfiguration:
      postgresql:
        parameters:
          wal_level: logical
  standby:
    enabled: true
    repoName: repo1
```

**MySQL:**
- Galera Cluster für synchrone Multi-Master
- MySQL Group Replication
- InnoDB Cluster

**NoSQL:**
- MongoDB Replica Sets über Regions
- Cassandra Multi-DC Replication
- Redis Sentinel mit Cross-DC Replication

### Global Load Balancing (GSLB)

#### Cloudflare Load Balancer
```json
{
  "name": "app.example.com",
  "default_pools": ["eu-central-pool", "us-east-pool"],
  "region_pools": {
    "WEUR": ["eu-central-pool"],
    "EEU": ["eu-central-pool"],
    "NAM": ["us-east-pool"]
  },
  "steering_policy": "geo"
}
```

#### AWS Route53
```yaml
# Terraform Beispiel
resource "aws_route53_record" "app" {
  zone_id = var.zone_id
  name    = "app.example.com"
  type    = "A"
  
  geolocation_routing_policy {
    continent = "EU"
  }
  
  alias {
    name                   = aws_lb.eu_cluster.dns_name
    zone_id                = aws_lb.eu_cluster.zone_id
    evaluate_target_health = true
  }
}
```

### Multi-Cluster Monitoring

**Prometheus Federation**
```yaml
# Zentrale Prometheus-Instanz
scrape_configs:
- job_name: 'federate-cluster1'
  honor_labels: true
  metrics_path: '/federate'
  params:
    'match[]':
    - '{job="kubernetes-pods"}'
  static_configs:
  - targets:
    - 'prometheus-cluster1.monitoring:9090'
    labels:
      cluster: cluster1
```

**Thanos für Multi-Cluster**
- Zentrale Object Storage für Metriken
- Global Query Layer
- Cross-Cluster Alerting

**Grafana Multi-Cluster Dashboards**
- Cluster-Selector per Variable
- Aggregierte Ansichten über Cluster
- Geo-Maps für Traffic-Distribution

### Failover-Strategien

#### DNS-basiert
```yaml
# External-DNS mit Healthcheck
apiVersion: v1
kind: Service
metadata:
  annotations:
    external-dns.alpha.kubernetes.io/hostname: app.example.com
    external-dns.alpha.kubernetes.io/set-identifier: cluster1
    external-dns.alpha.kubernetes.io/aws-weight: "100"
    external-dns.alpha.kubernetes.io/aws-health-check-id: <id>
```

**Eigenschaften:**
- RTO: TTL-abhängig (typisch 60-300s)
- Einfach zu implementieren
- Keine zusätzliche Infrastruktur

#### Application-Level Failover
- Circuit Breaker in Service Mesh
- Retry-Logic mit Fallback-Cluster
- Client-Side Load Balancing

### Tools & Komponenten Übersicht

| Kategorie | Tool | Zweck |
|-----------|------|-------|
| **Cluster Management** | Rancher | Multi-Cluster UI, Management |
| | KubeFed (deprecated) | Cluster Federation (Legacy) |
| **Networking** | Submariner | Pod-to-Pod Communication |
| | Cilium Cluster Mesh | eBPF Multi-Cluster |
| **Service Mesh** | Istio Multi-Cluster | Service-to-Service Communication |
| | Linkerd SMI | Lightweight Service Mesh |
| **GitOps** | ArgoCD | Multi-Cluster Deployments |
| | Flux | GitOps Engine |
| **Load Balancing** | Cloudflare | GSLB, DDoS Protection |
| | F5 GTM | Enterprise GSLB |
| | AWS Route53 | Geo-Routing, Healthchecks |
| **Monitoring** | Thanos | Multi-Cluster Prometheus |
| | Grafana | Unified Dashboards |
| **Disaster Recovery** | Velero | Backup/Restore |
| | Kasten K10 | Enterprise Backup |

### Implementierungs-Beispiel: 2-Cluster Active-Active

**Architektur:**
```
Internet
    |
[Cloudflare GSLB]
    |
    ├── EU Cluster (Frankfurt)
    │   ├── Ingress (Nginx)
    │   ├── Application Pods (3x)
    │   └── PostgreSQL (Primary)
    │
    └── US Cluster (Virginia)
        ├── Ingress (Nginx)
        ├── Application Pods (3x)
        └── PostgreSQL (Read Replica)
```

**Deployment:**
1. **Basis-Setup:**
```bash
# Beide Cluster mit ArgoCD verbinden
argocd cluster add eu-cluster
argocd cluster add us-cluster
```

2. **ApplicationSet:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: web-app
spec:
  generators:
  - clusters:
      selector:
        matchLabels:
          env: production
  template:
    spec:
      project: default
      source:
        repoURL: https://github.com/org/apps
        path: web-app/overlays/{{values.cluster}}
        targetRevision: main
      destination:
        name: '{{name}}'
        namespace: production
```

3. **Datenbank-Replikation (PostgreSQL):**
```yaml
# Primary Cluster (EU)
apiVersion: postgres-operator.crunchydata.com/v1beta1
kind: PostgresCluster
metadata:
  name: web-db
spec:
  postgresVersion: 15
  instances:
  - name: instance1
    replicas: 2

# Replica Cluster (US) - Logical Replication
# Subscription zu EU Cluster
```

4. **Service Mesh (Istio):**
```bash
# Multi-Primary Installation
istioctl install --set values.global.meshID=mesh1 \
  --set values.global.multiCluster.clusterName=eu-cluster \
  --set values.global.network=eu-network

istioctl install --set values.global.meshID=mesh1 \
  --set values.global.multiCluster.clusterName=us-cluster \
  --set values.global.network=us-network
```

5. **GSLB (Cloudflare):**
```bash
# Cloudflare Load Balancer mit Geo-Steering
curl -X POST "https://api.cloudflare.com/client/v4/zones/<zone>/load_balancers" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "app.example.com",
    "default_pools": ["eu-pool", "us-pool"],
    "region_pools": {
      "WEUR": ["eu-pool"],
      "NAM": ["us-pool"]
    },
    "steering_policy": "geo"
  }'
```

### Vor-/Nachteile

**Vorteile:**
- Echte Geo-Redundanz (RZ-unabhängig)
- Keine etcd-Latenz-Limitierung
- Unabhängige Cluster-Updates
- Flexible Failover-Strategien
- Data Residency Compliance möglich

**Nachteile:**
- Höchste Komplexität
- Daten-Konsistenz Herausforderungen
- Höhere Betriebskosten
- Mehr Tooling erforderlich
- Manueller Aufwand für Synchronisation

### Kostenabschätzung
- **Relativ:** 2-3x pro Cluster (Minimum 2 Cluster)
- **Zusatzkosten:** GSLB, Service Mesh, GitOps-Tooling

### RTO/RPO

| Strategie | RTO | RPO |
|-----------|-----|-----|
| Active-Passive (manuell) | 5-15 min | 1-5 min |
| Active-Passive (auto) | 1-5 min | 1-5 min |
| Active-Active | < 1 min | Sekunden-Minuten |

### Quellen
- [Kubernetes Multi-Cluster Networking](https://kubernetes.io/blog/2021/12/22/kubernetes-1-23-dual-stack-ipv6/)
- [Submariner Documentation](https://submariner.io/)
- [Istio Multi-Cluster](https://istio.io/latest/docs/setup/install/multicluster/)
- [ArgoCD ApplicationSet](https://argo-cd.readthedocs.io/en/stable/user-guide/application-set/)
- [Flux Multi-Cluster](https://fluxcd.io/flux/use-cases/multi-cluster/)

---

## FALL 5: Hybrid/Edge Scenarios

### Ausgangssituation
- Kombination aus Cloud und On-Premise
- Edge-Locations mit eingeschränkter Connectivity
- IoT/Industrial Use Cases
- Retail Stores, Remote Sites

### Sinnvoll wenn:
- Data Sovereignty erforderlich (On-Premise)
- Latenz-kritische Workloads am Edge
- Offline-Fähigkeit erforderlich
- Schrittweise Cloud-Migration
- Budget: Variabel

### Lightweight Kubernetes Distributionen

#### K3s
```bash
# Master Installation
curl -sfL https://get.k3s.io | sh -

# Agent (Edge) Installation
curl -sfL https://get.k3s.io | K3S_URL=https://master:6443 \
  K3S_TOKEN=<token> sh -
```

**Eigenschaften:**
- Minimaler Footprint (<512 MB RAM)
- SQLite statt etcd (für single-master)
- Integrierter Load Balancer (ServiceLB)
- Ideal für Edge-Deployments

#### MicroK8s
```bash
# Installation
snap install microk8s --classic

# HA-Cluster
microk8s add-node
microk8s join <master-ip>:<port>/<token>
```

**Eigenschaften:**
- Snap-basiert, Auto-Updates
- Add-Ons für DNS, Storage, Ingress
- Gut für Desktop/Dev-Environments

#### KubeEdge
```bash
# Cloud-Seite
keadm init --advertise-address=<cloud-ip>

# Edge-Seite
keadm join --cloudcore-ipport=<cloud-ip>:10000 \
  --token=<token>
```

**Eigenschaften:**
- Speziell für IoT/Edge
- Offline-Autonomie
- Lightweight Edge-Runtime
- Cloud-Edge Message Bus

### Hybrid-Cluster Management

#### Rancher
- Zentrale UI für alle Cluster (Cloud + On-Prem)
- Multi-Cluster App Catalog
- RBAC und Policy Management
- Monitoring über Cluster hinweg

#### VMware Tanzu
- Enterprise Kubernetes für Hybrid Cloud
- Integration mit vSphere
- Consistent Operations überall

### Connectivity-Patterns

**VPN-Mesh:**
```
Cloud Cluster
    |
[WireGuard VPN]
    |
    ├── Branch Office 1 (K3s)
    ├── Branch Office 2 (K3s)
    └── Edge Device (KubeEdge)
```

**Hub-and-Spoke:**
- Zentraler Hub-Cluster (Cloud)
- Spoke-Cluster (Edge/Branch)
- Submariner für Pod-Connectivity

### Edge-Specific Patterns

**Edge-Autonomy:**
```yaml
# Application läuft lokal, synchronisiert bei Connectivity
apiVersion: apps/v1
kind: Deployment
metadata:
  name: edge-app
  annotations:
    edge.kubernetes.io/offline-capable: "true"
spec:
  replicas: 1
  template:
    spec:
      nodeSelector:
        edge-location: retail-store-42
```

**Data Sync:**
- Lokale Datenerfassung am Edge
- Batch-Upload bei Connectivity
- Conflict Resolution bei Sync

### Tools & Komponenten

- **K3s**: Lightweight Kubernetes
- **MicroK8s**: Snap-based Kubernetes
- **KubeEdge**: Cloud-Edge Framework
- **Rancher**: Multi-Cluster Management
- **Submariner**: Hybrid Networking
- **Flux/ArgoCD**: GitOps auch für Edge

### Vor-/Nachteile

**Vorteile:**
- Flexible Deployment-Optionen
- On-Premise Data Residency
- Niedrige Latenz am Edge
- Offline-Fähigkeit

**Nachteile:**
- Management-Komplexität
- Heterogene Infrastruktur
- Connectivity-Abhängigkeit
- Update-Management schwierig

### Kostenabschätzung
- **Cloud:** 1-2x Standard-Cluster
- **Edge:** Hardware + K3s (minimal)
- **Gesamt:** Stark use-case abhängig

### RTO/RPO
- **Cloud-Edge:** Abhängig von Connectivity
- **Edge-Autonomie:** RTO < 1min (lokal), RPO variabel

### Quellen
- [K3s Documentation](https://docs.k3s.io/)
- [MicroK8s Documentation](https://microk8s.io/docs)
- [KubeEdge Documentation](https://kubeedge.io/)
- [Rancher Documentation](https://ranchermanager.docs.rancher.com/)

---

## Entscheidungsmatrix

| Kriterium | Fall 1 | Fall 2 | Fall 3 | Fall 4 | Fall 5 |
|-----------|--------|--------|--------|--------|--------|
| **RZ-Anzahl** | 1 | 1 (Multi-Zone) | 2-3 | 2+ | Hybrid |
| **RTT Control Plane** | < 1ms | < 10ms | < 10ms | > 10ms | Variabel |
| **RTO** | 1-5 min | < 1 min | < 1 min | 1-10 min | Variabel |
| **RPO** | < 1 min | 0 | 0 | Sek-Min | Variabel |
| **Komplexität** | Niedrig | Mittel | Sehr Hoch | Hoch | Hoch |
| **Kosten (relativ)** | 1x | 1.5-2x | 3-4x | 2-3x/Cluster | Variabel |
| **Geo-Redundanz** | ❌ | ✅ (Zones) | ✅ (RZ) | ✅✅ | ✅ |
| **Empfehlung** | Standard | Cloud-Native | ⚠️ Nur bei Zwang | ✅ Empfohlen | Use-Case |

---

## Best Practices (Übergreifend)

### 1. Observability
```yaml
# Monitoring Stack
- Prometheus + Thanos (Multi-Cluster)
- Grafana (Unified Dashboards)
- Loki (Logging)
- Jaeger/Tempo (Tracing)
- Alertmanager (Alerting)
```

### 2. Chaos Engineering
```bash
# Chaos Mesh für HA-Testing
kubectl apply -f chaos-mesh.yaml

# Network Latency Simulation
kubectl apply -f - <<EOF
apiVersion: chaos-mesh.org/v1alpha1
kind: NetworkChaos
metadata:
  name: network-delay
spec:
  action: delay
  mode: all
  selector:
    namespaces:
      - production
  delay:
    latency: "100ms"
  duration: "5m"
EOF
```

### 3. Disaster Recovery Drills
- Regelmäßige Failover-Tests
- Dokumentierte Runbooks
- Automatisierte Recovery-Procedures

### 4. Backup-Strategie
```bash
# Velero Scheduled Backups
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --ttl 720h \
  --include-namespaces production,staging

# Cross-Region Backup
velero backup-location create aws-eu-west \
  --provider aws \
  --bucket velero-backups-eu \
  --config region=eu-west-1
```

### 5. Security Hardening
- Network Policies zwischen Namespaces
- Pod Security Standards (restricted)
- RBAC mit Least Privilege
- Secret Management (Vault, Sealed Secrets)
- Supply Chain Security (Sigstore, cosign)

### 6. Cost Optimization
- Cluster Autoscaling
- Vertical Pod Autoscaling
- Spot/Preemptible Instances (wo möglich)
- Resource Quotas und Limits
- Multi-Tenancy für shared infrastructure

---

## Migrationspfade

### Von Fall 1 zu Fall 2
```
1. Cloud-Provider Setup (AWS, GCP, Azure)
2. Multi-AZ Control Plane migrieren
3. Workloads mit Zone-Awareness deployen
4. Storage zu Zone-Aware migrieren
5. Monitoring für Zone-Health
```

### Von Fall 1 zu Fall 4
```
1. Zweiten Cluster aufsetzen
2. GitOps-Pipeline (ArgoCD/Flux)
3. Datenbank-Replikation konfigurieren
4. Traffic-Splitting testen (10/90 → 50/50)
5. GSLB aktivieren
6. Full Active-Active
```

### Von Fall 2 zu Fall 4
```
1. Zusätzliche Region-Cluster
2. Multi-Cluster Networking (Submariner/Cilium)
3. Service Mesh über Cluster
4. Cross-Region Daten-Replikation
5. GSLB konfigurieren
```

---

## Tooling Comparison

### GitOps: ArgoCD vs Flux

| Feature | ArgoCD | Flux |
|---------|--------|------|
| **UI** | ✅ Web UI | ❌ CLI only (FluxCD UI 3rd party) |
| **Multi-Cluster** | ✅ Native | ✅ Multi-tenancy |
| **RBAC** | ✅ Integriert | ⚠️ Kubernetes RBAC |
| **Sync Waves** | ✅ Hooks | ✅ Dependencies |
| **Helm** | ✅ Native | ✅ HelmRelease CRD |
| **Kustomize** | ✅ | ✅ |
| **Image Updates** | ⚠️ Image Updater | ✅ Image Automation |
| **Resource Usage** | Höher | Niedriger |

**Empfehlung:** ArgoCD für Enterprise mit UI-Bedarf, Flux für GitOps-Puristen

### Service Mesh: Istio vs Linkerd vs Cilium

| Feature | Istio | Linkerd | Cilium Service Mesh |
|---------|-------|---------|---------------------|
| **Multi-Cluster** | ✅ Mature | ✅ | ✅ Cluster Mesh |
| **Complexity** | Hoch | Niedrig | Mittel |
| **Performance** | Mittel | Hoch | Sehr Hoch (eBPF) |
| **mTLS** | ✅ | ✅ | ✅ |
| **Traffic Mgmt** | ✅✅ | ✅ | ✅ |
| **Observability** | ✅✅ | ✅ | ✅ |
| **Resource Usage** | Hoch | Niedrig | Niedrig |

**Empfehlung:** Linkerd für Einfachheit, Istio für Features, Cilium für Performance

### Backup: Velero vs Kasten K10

| Feature | Velero | Kasten K10 |
|---------|--------|-----------|
| **Cost** | ✅ Open Source | 💰 Commercial |
| **Snapshot Support** | ✅ CSI | ✅ CSI + App-Consistent |
| **App-Aware** | ⚠️ Hooks | ✅ Native |
| **DR** | ✅ | ✅ |
| **Policy Mgmt** | ⚠️ Basic | ✅ Advanced |
| **UI** | ❌ | ✅ |
| **Multi-Cluster** | ⚠️ Manual | ✅ Automated |

**Empfehlung:** Velero für OSS/Budget, Kasten K10 für Enterprise

---

## Checkliste: HA-Readiness

### Infrastructure
- [ ] Redundante Control Plane Nodes (min. 3)
- [ ] Worker Nodes über Failure Domains verteilt
- [ ] Storage mit Replikation
- [ ] Redundante Netzwerk-Pfade
- [ ] Load Balancer für API Server
- [ ] Backup-Lösung konfiguriert
- [ ] Monitoring und Alerting

### Application
- [ ] Deployments mit min. 3 Replicas
- [ ] PodDisruptionBudgets definiert
- [ ] Health Checks (Readiness/Liveness)
- [ ] Resource Limits gesetzt
- [ ] Anti-Affinity Rules konfiguriert
- [ ] StatefulSets für stateful Apps
- [ ] Graceful Shutdown implementiert

### Data
- [ ] Datenbank mit HA-Setup
- [ ] Backup-Strategie (automatisiert)
- [ ] Disaster Recovery getestet
- [ ] RTO/RPO dokumentiert
- [ ] Daten-Replikation (bei Multi-RZ)

### Operations
- [ ] Runbooks dokumentiert
- [ ] Disaster Recovery-Drill durchgeführt
- [ ] On-Call Rotation
- [ ] Incident Response Plan
- [ ] Change Management Process
- [ ] Capacity Planning

### Security
- [ ] Network Policies aktiv
- [ ] Pod Security Standards enforced
- [ ] Secret Management (Vault/Sealed Secrets)
- [ ] RBAC konfiguriert
- [ ] Audit Logging aktiviert
- [ ] Image Scanning in CI/CD

---

## Zusammenfassung & Empfehlungen

### Quick Decision Tree

```
Start
  |
  ├─ Ein RZ ausreichend?
  │   └─ JA → Fall 1 (Single-Cluster)
  │
  ├─ Cloud-Provider mit Zones?
  │   └─ JA → Fall 2 (Multi-Zone)
  │
  ├─ RTT < 10ms zwischen RZ?
  │   ├─ JA → ⚠️ Fall 3 (Stretched) - nur bei Zwang!
  │   └─ NEIN → Fall 4 (Multi-Cluster) ✅
  │
  └─ Edge/Hybrid?
      └─ JA → Fall 5 (Hybrid/Edge)
```

### Pragmatische Empfehlungen

1. **Start Simple**: Fall 1 (Single-Cluster) ist für 80% ausreichend
2. **Cloud-Native**: Fall 2 (Multi-Zone) bei Cloud-Deployment
3. **Avoid Stretched Clusters**: Fall 3 nur bei regulatorischen Zwängen
4. **Go Multi-Cluster**: Fall 4 für echte Geo-Redundanz
5. **Edge wenn nötig**: Fall 5 nur für spezifische Use Cases

### Typische Fehler vermeiden

❌ **Stretched Cluster bei hoher Latenz** → Split-Brain Risiko  
✅ **Multi-Cluster stattdessen**

❌ **Keine PodDisruptionBudgets** → Outage bei Node-Drain  
✅ **PDBs für alle kritischen Apps**

❌ **Single Replica für kritische Services** → No HA  
✅ **Min. 3 Replicas + Anti-Affinity**

❌ **Keine Backup-Tests** → DR funktioniert nicht  
✅ **Regelmäßige Restore-Drills**

❌ **etcd ohne Monitoring** → Unerkannte Performance-Issues  
✅ **etcd-Metriken + Alerts**

---

## Weiterführende Ressourcen

### Offizielle Dokumentation
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [etcd Operations Guide](https://etcd.io/docs/v3.5/op-guide/)
- [CNCF Landscape](https://landscape.cncf.io/)

### Bücher
- "Kubernetes: Up and Running" (O'Reilly)
- "Production Kubernetes" (O'Reilly)
- "Kubernetes Patterns" (O'Reilly)

### Tools & Projekte
- [Awesome Kubernetes](https://github.com/ramitsurana/awesome-kubernetes)
- [Kubernetes Failure Stories](https://k8s.af/)
- [Kubernetes SIGs](https://github.com/kubernetes-sigs)

### Community
- [CNCF Slack](https://slack.cncf.io/)
- [Kubernetes Discourse](https://discuss.kubernetes.io/)
- [Reddit r/kubernetes](https://reddit.com/r/kubernetes)

---

**Autor:** Claude (Anthropic)  
**Erstellt für:** Kubernetes HA Strategie-Workshop  
**Letzte Aktualisierung:** Dezember 2024  
**Feedback:** Weitere Szenarien oder Details gewünscht? Einfach nachfragen!
