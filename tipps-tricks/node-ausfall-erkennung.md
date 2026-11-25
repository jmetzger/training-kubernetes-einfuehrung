# Wie erkennt Kubernetes, dass ein Node ausgefallen ist?

Der Node meldet sich aktiv per **Heartbeat** beim Control Plane. Bleibt die Meldung aus, markiert der Control Plane ihn als nicht erreichbar, sperrt ihn per Taint und plant seine Pods auf anderen Nodes neu.

## Normalbetrieb: Heartbeats

```mermaid
flowchart LR
    subgraph Node["Worker-Node"]
        K["kubelet"]
    end
    subgraph CP["Control Plane"]
        A["kube-apiserver / etcd<br/>Lease, Node.status"]
        C["kube-controller-manager<br/>Node-Lifecycle-Controller"]
    end
    K -- "Lease erneuern, alle 10 s" --> A
    K -- "NodeStatus, bei Änderung<br/>sonst alle 5 min" --> A
    C -. "watch" .-> A
```

Der kubelet sendet zwei Arten von Heartbeats:

| Heartbeat | Wo | Takt |
|-----------|----|------|
| **Lease** | Namespace `kube-node-lease` | ca. alle 10 s, sehr klein und billig |
| **NodeStatus** | `Node.status` (Conditions wie `Ready`, `MemoryPressure`, `DiskPressure`) | bei Änderung, sonst spätestens alle 5 min |

## Ablauf nach dem Ausfall

```mermaid
sequenceDiagram
    participant N as Node (kubelet)
    participant A as API-Server
    participant C as Node-Lifecycle-Controller
    participant S as Scheduler / ReplicaSet

    N-xA: Heartbeats bleiben aus (t = 0)
    Note over C: node-monitor-grace-period = 50 s
    C->>A: Ready = Unknown (t ≈ 50 s)
    C->>A: Taints setzen: unreachable / not-ready (NoExecute)
    Note over S: Keine neuen Pods mehr auf diesen Node
    Note over A: tolerationSeconds = 300 läuft ab
    A->>S: Pods werden gelöscht (t ≈ 5 min 50 s)
    S->>S: Pods auf gesunden Nodes neu erzeugen
```

1. **t = 0:** Der Node fällt aus (kubelet, VM oder Netzwerk). Es kommt kein Lease-Update mehr an.
2. **t ≈ 50 s:** Die Grace Period (`--node-monitor-grace-period`, Standard 50 s ab Kubernetes 1.32, davor 40 s) ist abgelaufen. Der Node-Lifecycle-Controller im `kube-controller-manager` setzt `Ready` auf `Unknown`. `kubectl get nodes` zeigt `NotReady`.
3. **Gleichzeitig:** Der Controller setzt die Taints
   - `node.kubernetes.io/unreachable:NoExecute`
   - `node.kubernetes.io/not-ready:NoExecute`
4. **Ab dem Taint:** Der Scheduler platziert keine neuen Pods mehr auf dem Node.
5. **t ≈ 5 min 50 s:** Jeder Pod hat automatisch eine Toleration für diese Taints mit `tolerationSeconds: 300`. Sie läuft 5 Minuten nach dem Taint ab. Dann werden die Pods gelöscht, und ReplicaSet bzw. Deployment erzeugen sie auf gesunden Nodes neu.

## Wichtige Details

- **StatefulSets** werden nicht automatisch verschoben. Kubernetes kann nicht wissen, ob der Pod noch läuft (Split-Brain-Gefahr). Hier hilft manuelles `kubectl delete pod --force` oder Node-Shutdown-Handling.
- Die Wartezeit lässt sich pro Pod mit einer eigenen Toleration und kürzerem `tolerationSeconds` verkürzen:

```yaml
tolerations:
  - key: node.kubernetes.io/unreachable
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 30
  - key: node.kubernetes.io/not-ready
    operator: Exists
    effect: NoExecute
    tolerationSeconds: 30
```

- In **Managed-Clustern (z. B. DOKS)** erkennt zusätzlich der Cloud-Controller-Manager, wenn die VM beim Provider nicht mehr existiert, und entfernt den Node sofort. Die 5-Minuten-Wartezeit entfällt dann.

## Zum Nachvollziehen

```bash
# Heartbeats der Nodes ansehen
kubectl get lease -n kube-node-lease

# Conditions eines Nodes
kubectl describe node <node> | grep -A8 Conditions

# Taints eines Nodes
kubectl get node <node> -o jsonpath='{.spec.taints}'
```

Ausfall simulieren:

```bash
# auf dem Worker-Node
sudo systemctl stop kubelet

# in einem zweiten Terminal
kubectl get nodes -w
```

Nach ca. 50 s steht der Node auf `NotReady`, nach ca. 5 min 50 s werden die Pods neu geplant.

## Messung im Cluster

Nachgestellt auf einem kubeadm-Cluster (Kubernetes v1.37.2, CNI Antrea 2.7.0) mit 1 Control Plane und 2 Workern. Auf `k8s-tln1-w1` wurde der kubelet gestoppt, ein Deployment mit 4 Replicas lief verteilt auf beide Worker.

| Zeit nach Stopp | Beobachtung |
|-----------------|-------------|
| 0 s | alle Nodes `Ready`, Leases werden erneuert |
| ca. 47 s | `k8s-tln1-w1` ist `NotReady`, Taints `unreachable:NoSchedule` und `unreachable:NoExecute` gesetzt |
| ca. 346 s | Pods von `w1` werden evakuiert, 4 Pods laufen auf `w2`, die alten stehen auf `Terminating` |

Die Zeiten passen zu 50 s Grace Period plus 300 s `tolerationSeconds` (gemessen ab dem letzten Heartbeat, nicht ab dem Stopp).

**1. Node erreichbar:** Leases aktuell, alle Nodes `Ready`

![Node erreichbar](../images/node-ausfall/1-node-erreichbar.png)

**2. Node ausgefallen:** Lease von `w1` steht, `NotReady`, Taints gesetzt

![Node NotReady](../images/node-ausfall/2-node-notready.png)

**3. Nach 5 Minuten:** Pods werden auf `w2` neu erzeugt

![Pods evakuiert](../images/node-ausfall/3-pods-evakuiert.png)

**Zeitachse**

![Zeitachse Node-Ausfall](../images/node-ausfall/zeitachse.png)
