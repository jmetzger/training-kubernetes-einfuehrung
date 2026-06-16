# NetworkPolicy - Pod-Traffic absichern

## Hintergrund

Ohne NetworkPolicy kann **jeder Pod mit jedem anderen Pod** im Cluster
kommunizieren — egal in welchem Namespace. Das ist der unsichere Standardzustand.

NetworkPolicies wirken wie eine Firewall auf Pod-Ebene:

| Konzept | Beschreibung |
|---------|-------------|
| `podSelector` | Fuer welche Pods gilt diese Policy |
| `policyTypes` | `Ingress`, `Egress` oder beides |
| `ingress.from` | Wer darf eingehenden Traffic schicken |
| `egress.to` | Wohin darf ausgehender Traffic gehen |
| Leere Policy | Blockiert alles (Default-Deny) |
| Keine Policy | Alles erlaubt |

**Wichtig:** NetworkPolicies werden vom CNI-Plugin durchgesetzt.
Unser Cluster verwendet **Calico** — Standard-NetworkPolicies funktionieren
hier vollstaendig. Mehr dazu am Ende der Uebung.

---

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 21-networkpolicy
cd 21-networkpolicy
```

Namespace anlegen:

```
kubectl create namespace networkpolicy-<dein-name>
```

---

## Schritt 2: Ausgangslage — kein Schutz

Frontend- und Backend-Pod anlegen:

```
# vi 00-baseline.yml
apiVersion: v1
kind: Pod
metadata:
  name: backend
  labels:
    app: backend
spec:
  containers:
  - name: app
    image: nginx:1.27
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
  labels:
    app: frontend
spec:
  containers:
  - name: web
    image: nginx:1.27
    ports:
    - containerPort: 80
```

```
kubectl apply -f . -n networkpolicy-<dein-name>
kubectl get pod,svc -n networkpolicy-<dein-name>
```

Warten bis beide Pods laufen:

```
kubectl wait pod frontend backend --for=condition=Ready -n networkpolicy-<dein-name> --timeout=60s
```

Frontend erreicht Backend — kein Problem:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s http://backend | grep title
```

**Erwartete Ausgabe:** nginx-Titelzeile — Verbindung funktioniert ungehindert.

---

## Schritt 3: Default-Deny — alles blockieren

Die erste und wichtigste Policy: keinen Traffic erlauben, den wir nicht
explizit freigegeben haben.

```
# vi 01-default-deny.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

`podSelector: {}` bedeutet: gilt fuer **alle** Pods im Namespace.

```
kubectl apply -f . -n networkpolicy-<dein-name>
```

Verbindung testen:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s --max-time 5 http://backend
```

**Erwarteter Fehler:**
```
curl: (28) Connection timed out after 5000 milliseconds
```

Auch DNS ist jetzt geblockt:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s --max-time 5 http://example.com
```

**Erwarteter Fehler:** Timeout — kein Egress, kein DNS.

---

## Schritt 4: DNS freigeben

Ohne DNS koennen Pods keine Servicenamen aufloesen. Wir erlauben
Egress zu kube-dns im `kube-system`-Namespace.

```
# vi 02-allow-dns.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

```
kubectl apply -f . -n networkpolicy-<dein-name>
```

DNS testen:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- getent hosts backend
```

**Erwartete Ausgabe:** IP-Adresse wird aufgeloest (z.B. `10.96.x.x  backend.default.svc.cluster.local`).

HTTP zu Backend schlaegt aber noch fehl:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s --max-time 5 http://backend
```

**Erwarteter Fehler:** Timeout — HTTP-Traffic noch gesperrt.

---

## Schritt 5: Frontend darf Backend auf Port 80 erreichen

```
# vi 03-frontend-to-backend.yml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress-to-backend
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-ingress-from-frontend
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
```

```
kubectl apply -f . -n networkpolicy-<dein-name>
```

Verbindung testen:

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s http://backend | grep title
```

**Erwartete Ausgabe:** nginx-Titelzeile — Verbindung funktioniert wieder.

---

## Schritt 6: Isolation verifizieren

Externer Traffic bleibt gesperrt (Egress-Deny greift):

```
kubectl exec -n networkpolicy-<dein-name> frontend -- curl -s --max-time 5 http://www.google.de
```

**Erwarteter Fehler:** Timeout.

Backend kann Frontend **nicht** erreichen (kein Egress vom Backend freigegeben):

```
kubectl exec -n networkpolicy-<dein-name> backend -- curl -s --max-time 5 http://frontend
```

**Erwarteter Fehler:** Timeout.

Alle aktiven NetworkPolicies anzeigen:

```
kubectl get networkpolicy -n networkpolicy-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                          POD-SELECTOR    AGE
allow-dns                     <none>          ...
backend-ingress-from-frontend app=backend     ...
default-deny-all              <none>          ...
frontend-egress-to-backend    app=frontend    ...
```

---

## Grenzen von Standard-NetworkPolicies

Standard-NetworkPolicies koennen nur nach **IP, Port und Pod/Namespace-Label**
filtern — keine Domainnamen, keine L7-Regeln.

| Anforderung | Standard-NP | Calico CRD |
|-------------|------------|------------|
| Pod-zu-Pod nach Label | ja | ja |
| Namespace-Isolation | ja | ja |
| Default-Deny cluster-weit | nein | ja (`GlobalNetworkPolicy`) |
| Egress nach Domainname (FQDN) | nein | ja (`NetworkSet` + FQDN) |
| HTTP-Methoden / Pfade (L7) | nein | ja (mit Istio/Cilium) |

Wer Calico als CNI hat, kann mit `GlobalNetworkPolicy` eine
**cluster-weite** Default-Deny-Policy setzen — ohne dass jeder Namespace
seine eigene anlegen muss:

```
# Beispiel: Calico GlobalNetworkPolicy (kein Standard-Kubernetes!)
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: default-deny
spec:
  selector: all()
  types:
  - Ingress
  - Egress
```

Referenz: https://docs.tigera.io/calico/latest/network-policy/networkpolicy-get-started

---

## Aufraeumen

```
kubectl delete namespace networkpolicy-<dein-name>
```

---

## Zusammenfassung

| Policy | Zweck |
|--------|-------|
| `default-deny-all` | Alles sperren — Ausgangsbasis |
| `allow-dns` | DNS fuer alle Pods freigeben |
| `frontend-egress-to-backend` | Frontend darf Backend ansprechen |
| `backend-ingress-from-frontend` | Backend nimmt nur vom Frontend an |

Die Kombination aus Default-Deny + gezielten Freigaben ist das
**Zero-Trust-Prinzip** auf Netzwerkebene.

## Referenzen

  * https://kubernetes.io/docs/concepts/services-networking/network-policies/
  * https://docs.tigera.io/calico/latest/network-policy/
