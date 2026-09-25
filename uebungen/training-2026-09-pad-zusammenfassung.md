# Training Kubernetes Einführung – Pad-Zusammenfassung

**Zeitraum:** 23.09. – 25.09.2026
**Quelle:** [yopad.eu/p/kubernetes](https://yopad.eu/p/kubernetes) (Stand 25.09.2026)

Dieses Dokument fasst das gemeinsame Etherpad des Trainings zusammen: alle Übungen und Infos in der Reihenfolge, in der wir sie durchgegangen sind, plus Zeitplan und Agenda-Status.

---

## Organisatorisches

| Was | Wo |
|---|---|
| Dokumentation / Agenda | [README.md](../README.md) |
| Jochen bewerten | <https://reviews.appv2.t3isp.de/E4U6> |
| Newsletter | j.metzger@t3company.de |
| Bastion-Client (SSH) | `client-aok.do.t3isp.de`, Port 22 |
| SSH-Client für Windows | [PuTTY](https://the.earth.li/~sgtatham/putty/latest/w64/putty.exe) |

Die Zuordnung der Teilnehmer zu den Logins `tln1` – `tln9` steht im Pad und wird hier bewusst nicht veröffentlicht.

### Zeitplanung

| Zeit | Block |
|---|---|
| 09:00 – 10:30 | Block I |
| 10:30 – 10:45 | Frühstück |
| 10:45 – 12:15 | Block II |
| 12:15 – 13:15 | Mittag |
| 13:15 – 14:45 | Block III |
| 14:45 – 15:00 | Teatime |
| 15:00 – 16:30 | Block IV |

---

## Tag 1 – Container, Kubernetes-Architektur, Pods, Deployments, Services

### Info 1.1 – Docker-Container auf dem Linux-System

Jochen malt: Wie ein Container auf dem Linux-System aufgebaut ist (Namespaces, Cgroups, Layer).

### Info 1.2 – Docker Container

* [Was ist ein Container?](../container.md)

### Info 1.3 – Docker Images

* [Was sind Container Images?](../container-images.md)

### Info 1.4 – Schaubild Architektur

* [Übersicht Architektur](../architektur.md)

### Info 1.5 – Kubernetes Aufbau

* [Kubernetes Architektur](../kubernetes/architecture.md)

### Übung 1.6 – Zugang zum Trainings-Client

Mit PuTTY oder `ssh` auf den Bastion-Client verbinden:

```bash
ssh tln<x>@client-aok.do.t3isp.de
```

### Übung 1.7 – kubectl einrichten

* [kubectl einrichten mit Namespace](../kubectl/kubectl-einrichten.md)

### Übung 1.8 – Pod mit `kubectl run`

* [kubectl run – Beispiel](../kubectl/run-with-example.md)

### Info 1.9 – Applikation aus Standardobjekten bauen

* [Bauen einer Webanwendung mit Resource-Objekten](../bauen-einer-webanwendung.md)

### Info 1.10 – Anatomie einer Webanwendung

* [Anatomie einer Webanwendung](../anatomie-einer-webanwendung.md)

### Übung 1.11 – Pod mit Manifest

* [Pod nginx (Manifest)](../kubectl-examples/01-pod-nginx.md)

### Übung 1.12 – Walkthrough: ReplicaSet erstellen

* [ReplicaSet – Walkthrough Erstellen](../kubectl-examples/01a-replicaset-nginx.md#walkthrough-erstellen)

### Übung 1.13 – ReplicaSet erstellen

Nur den Punkt „Erstellen" bearbeiten.

* [ReplicaSet nginx](../kubectl-examples/01a-replicaset-nginx.md)

### Übung 1.14 – Deployment

* [Deployment nginx](../kubectl-examples/03-nginx-deployment.md)

### Übung 1.15 – Services (ClusterIP)

* [Service – Example I: ClusterIP](../kubectl-examples/03b-service.md#example-i--service-with-clusterip)

### Übung 1.16 – Netzverbindung testen

```bash
# IP-Adresse eines Pods aus dem Deployment ermitteln
kubectl get pods -o wide

# IP des Services
kubectl get svc svc-nginx -o wide

# Test-Pod starten (wird nach dem Beenden automatisch gelöscht)
kubectl run podtest --rm -it --image busybox
```

Innerhalb des Test-Pods:

```bash
ping -c4 <pod-ip>
wget -O - <pod-ip>
ping -c4 <cluster-ip>
wget -O - <cluster-ip>
exit
```

### Übung 1.17 – NodePort

* [Service – Example II: NodePort](../kubectl-examples/03b-service.md#example-ii--short-version-nodeport)

### Übung 1.18 – LoadBalancer (Example III)

* [Service – Example III: LoadBalancer / ExternalIP](../kubectl-examples/03b-service.md#example-iii-service-mit-loadbalancer-externalip)

### Übung 1.19 – DNS-basierte Verbindungen

* [DNS Resolution – Services](../kubernetes-networks/dns-resolution-services.md)

### Info 1.20 – Ingress Controller

* [Traefik Ingress Controller mit Helm installieren](../ingress/traefik/install-with-helm.md)

---

## Tag 2 – Ingress, ConfigMaps, Secrets, Vault, Helm

### Übung 2.1 – Ingress mit Hostnamen (Schritt 1: Deployment und Services)

Vorher aufräumen:

```bash
cd
cd manifests/04-service
kubectl delete -f .
```

* [Ingress mit Traefik und Hostnamen](../kubectl-examples/04-ingress-traefik-with-hostnames-deployment.md)

### Übung 2.2 – Ingress bis Schritt 4.1 (inklusive)

Thema: `kind` und die „Landkarte" der API-Groups.

### Übung 2.3 – Ingress mit SSL / TLS

* [Ingress-Objekt mit TLS erstellen (Schritt 3)](../ingress/https-letsencrypt-ingress-traefik.md#schritt-3-ingress-objekt-mit-tls-erstellen)

### Übung 2.4 – ConfigMap mit MariaDB (Schritt 1 + 2)

* [ConfigMap Example MariaDB](../kubectl-examples/06a-configmap-mariadb.md)

### Übung 2.5 – Umbau auf Secret

Secret-Manifest per Dry-Run erzeugen:

```bash
kubectl create secret generic mariadb-secret \
  --from-literal=MARIADB_ROOT_PASSWORD=<passwort> \
  --dry-run=client -o yaml > 01-secrets.yml
```

Dann in `02-deploy.yml` anpassen:

* `configMapRef:` → `secretRef:`
* `mariadb-configmap` → `mariadb-secret`

```bash
kubectl apply -f .
kubectl get pods   # Läuft der Pod?
```

### Info 2.6 – Vault

* [HashiCorp Vault – Architektur einfach erklärt](../hashicorp-vault/architektur-einfach-erklaert.md)
* Ausführlich im Advanced-Workshop: [workshop-kubernetes-advanced-2026-Q3](https://github.com/jmetzger/workshop-kubernetes-advanced-2026-Q3/blob/main/hashicorp-vault/architektur-einfach-erklaert.md)

### Info 2.7 – Helm Grundlagen

* [Helm Grundlagen](../helm/grundlagen.md)

### Übung 2.8 – Helm Chart installieren (Schritt 1)

* [MariaDB mit Helm (cloudpirates)](../exercises/install/mariadb-cloudpirates.md)

### Übung 2.9 – Helm Chart Upgrade (Schritt 2)

* [Upgrade auf neue Version](../exercises/install/mariadb-cloudpirates.md#schritt-2-exercise-upgrade-to-new-version)

### Übung 2.10 – Upgrade mit Deinstallation (Schritt 3)

* [Upgrade mit Deinstallation](../exercises/install/mariadb-cloudpirates.md#schritt-3-exercise-upgrade-to-new-version)

---

## Tag 3 – CNCF, Storage, RBAC, QoS, Autoscaling, StatefulSets, Monitoring

### Übung 3.1 – CNCF Landscape

* <https://landscape.cncf.io>

### Übung 3.2 – NFS mit Pod (CSI)

* [NFS Exercise – Persistent Volume Claim (ab Step 3)](../kubernetes-csi/nfs-exercise.md#step-3-persistent-volume-claim)

### Übung 3.3 – Traefik: RBAC-Analyse

```bash
kubectl get ns                      # Gibt es einen Namespace "ingress"?
kubectl -n ingress get sa
kubectl -n ingress get sa traefik
```

**Quizfrage:** Ihr wollt herausfinden, ob im Traefik-Pod wirklich der ServiceAccount `traefik` eingehängt ist. Wie seht ihr das?

```bash
kubectl -n ingress get pod <traefik-pod> -o yaml | grep serviceAccount
```

Weiter mit Rollen und ClusterRoles:

```bash
kubectl -n traefik get roles                   # Rolle traefik?
kubectl get clusterroles | grep traefik
kubectl get clusterrole <clusterrole-fuer-traefik> -o yaml
```

Siehe auch: [Kubernetes RBAC – was darf Traefik](../kubernetes-rbac/was-darf-traefik.md)

### Übung 3.4 – RoleBinding / ClusterRoleBinding

```bash
kubectl get clusterrolebinding | grep traefik-ingress
```

### Info 3.5 – „Ich darf alles": ClusterRole

Diskussion: Was bedeutet eine ClusterRole mit vollen Rechten, und warum sollte man das vermeiden.

### Übung 3.6 – Pod suchen und Quality of Service ablesen

```bash
kubectl describe pods <name-des-pods> | grep QoS
```

* Hintergrund: [Quality of Service – evict pods](../kubernetes/qos-class.md)

### Übung 3.7 – Horizontal Pod Autoscaler

* [Kubernetes Autoscaling](../kubernetes/autoscaling.md)

### Übung 3.8 – StatefulSet

* [Example StatefulSet](../kubectl-examples/10-statefulset.md)

### Info 3.9 – Monitoring

* [Prometheus Monitoring Server (Overview)](../prometheus/overview.md)
* [Prometheus / Grafana Stack installieren](../prometheus-grafana/install-with-helm.md)

### Übung 3.10 – Prometheus GUI

* [Übung: Prometheus UI und PromQL](../prometheus-grafana/uebung-prometheus-ui-promql.md)

### Übung 3.11 – Metrics-Endpunkt direkt scrapen

```bash
kubectl run metrics-check -it --rm --image=curlimages/curl \
  --restart=Never -- \
  curl -s http://node-exporter.monitoring.svc.cluster.local:9100/metrics \
  | head -40
```

* [Schritt 2: Metrics direkt ansehen](../prometheus-grafana/uebung-prometheus-ui-promql.md#schritt-2-metrics-direkt-ansehen)

### Übung 3.12 – Readiness Probe

* [Übung: Readiness Probe mit HTTP](../kubectl-examples/03c-readiness-probe.md)

---

## Offene Themen / Wünsche aus dem Training

* Kong Gateway Operator
* PostgreSQL mit CloudNativePG → [HA mit dem Postgres Operator](../databases/postgresql/operator/cloudnativepg.md)

---

## Agenda-Status (Abgleich mit der offiziellen Agenda)

Legende: ✅ behandelt · 🔄 laufend · ⬜ offen

### Kubernetes Grundlagen

| Thema | Status |
|---|---|
| Motivation für Container und Möglichkeiten der Containertechnologie | ✅ |
| Einführung in Containertechnologie und das Arbeiten mit Containern | ✅ |
| Docker Ecosystem | ✅ |
| Linux Kernelfunktionen | ✅ |
| Vergleich Systemvirtualisierung und Container | ✅ |
| Design-Prinzipien für Cloud-Native-Anwendungen | ⬜ |

### Einführung in Kubernetes

| Thema | Status |
|---|---|
| Motivation für eine Orchestrierungsplattform | ✅ |
| Vorteile und Kosten von Kubernetes | ✅ |
| Eigenschaften von Kubernetes im Überblick | ⬜ |

### Kubernetes Architektur und Konzept

| Thema | Status |
|---|---|
| System-Übersicht mit allen Komponenten (API Server, Controller Manager, Scheduler) | ✅ |
| Installations-Optionen (Cloud, Minikube, etc.) | ⬜ |

### Setup der Arbeitsumgebung und Nutzen der CLI

| Thema | Status |
|---|---|
| Config-File und der Arbeitsbereich (Context) | ✅ |
| CLI-Tool (kubectl) | 🔄 |
| Imperatives und deklaratives Management | ✅ |

### Pod-Konzept

| Thema | Status |
|---|---|
| Pod-Konzept | ✅ |

### Flexibles Anwendungsdeployment

| Thema | Status |
|---|---|
| Arbeiten mit Labels und Label-Selektoren | ✅ |

### Workloads

| Thema | Status |
|---|---|
| Pods | ✅ |
| Deployments | ✅ |
| StatefulSets | ✅ (Übung 3.8) |
| DaemonSets | ⬜ |
| Jobs | ⬜ |

### Datenspeicher bereitstellen

| Thema | Status |
|---|---|
| Einfache Volumes | ⬜ |
| Persistente Volumes | ✅ (Übung 3.2) |

### Konfigurationsdaten und Secrets bereitstellen

| Thema | Status |
|---|---|
| ConfigMaps | ✅ |
| Secrets | ✅ |

### Netzwerkverbindungen bereitstellen

| Thema | Status |
|---|---|
| Architektur des Kubernetes-Netzwerks | ⬜ |
| Verbindungen zwischen Containern, Verbindungen nach außen | ✅ |
| Load Balancing und NodePort | ✅ |
| DNS-basierte Verbindungen | ✅ |
| Ingress | ✅ (Übungen 2.1 – 2.3) |

### Steuerung, Überwachung und Kontrolle von Anwendungen

| Thema | Status |
|---|---|
| Quality Class | ✅ (Übung 3.6) |
| Health Checks für Pods (Container) | ✅ (Übung 3.12) |
| Scheduling steuern (Taints und Tolerations) | ⬜ |

### Komplexe Anwendungen einfach deployen: Der Helm-Paketmanager

| Thema | Status |
|---|---|
| Paketformat | ✅ |
| Anwendungsdeployment vereinfachen | ✅ |
| Anwendungsdeployment flexibel gestalten | ✅ |
| Lifecycle-Management: Upgrade, Rollback und mehr | ✅ (Übungen 2.8 – 2.10) |
| Helm Charts und die Community | ✅ |

### Troubleshooting

| Thema | Status |
|---|---|
| Zugriff auf einen Pod (`kubectl exec`) | ⬜ fehlt noch |
| Netzwerkverbindungen testen | ✅ |
| Logging / Event-Infos des CLI-Tools | ⬜ |

### Zugriffskontrolle

| Thema | Status |
|---|---|
| Rollenbasierte Zugriffskontrolle | ✅ (Übungen 3.3 – 3.5) |
| Richtlinien | ⬜ |
| Service Accounts | ✅ (Übung 3.3) |

### Dashboard und andere GUI

| Thema | Status |
|---|---|
| Dashboard und andere GUI | ⬜ |

### Cluster-Erweiterungen

| Thema | Status |
|---|---|
| Monitoring und Logging (Fluentd, Elastic, Prometheus) | ✅ (Übungen 3.9 – 3.11) |
| Cluster DNS | ✅ |
| CNCF und Ausblick → [landscape.cncf.io](https://landscape.cncf.io) | ✅ (Übung 3.1) |
