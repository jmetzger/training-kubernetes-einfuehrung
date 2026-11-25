# Gateway API mit Traefik (Ergaenzung zu Ingress)

## Hintergrund

![Gateway API mit Traefik: Weg eines Requests](/images/gateway-api-traefik.svg)

Die Gateway API ist der Nachfolger von Ingress. Statt einer einzigen Ressource gibt es Rollen-getrennte Objekte:

| Ressource | Wer pflegt sie? | Aufgabe |
|-----------|-----------------|---------|
| GatewayClass | Infrastruktur-Anbieter | Welcher Controller (hier: Traefik) |
| Gateway | Cluster-Betreiber (Trainer) | Listener: Port, Protokoll, welche Namespaces duerfen anhaengen |
| HTTPRoute | Anwendungsentwickler (Teilnehmer) | Hostnamen, Pfade, Backends, Gewichtung |

Wichtig: Ein `Gateway` ist bei Traefik nur ein Konfigurationsobjekt und startet **keinen eigenen Pod**. Es gibt genau
einen Traefik-Pod (per Helm installiert), der alle Gateways und Routen liest und die passenden Listener oeffnet.
(Andere Implementierungen wie Cilium oder Envoy Gateway legen teils pro Gateway einen eigenen Proxy an.)

Vorteile gegenueber Ingress: Routing-Features (Header-Match, Gewichtung/Canary, Redirects) sind Teil des
Standards, statt in controller-spezifischen Annotations zu stecken.

Voraussetzung: Traefik ist installiert (siehe `ingress/traefik/install-with-helm.md`).
Es braucht **keine zweite Installation**: Derselbe Traefik bedient Ingress (`ingressClassName: traefik`) und
Gateway API (`gatewayClassName: traefik`) gleichzeitig, mit derselben LoadBalancer-IP. Die Trennung der beiden
Uebungen laeuft nur ueber die Domain: Ingress nutzt `*.appv2.do.t3isp.de`, Gateway API nutzt `*.app-gw.do.t3isp.de`
(beide Wildcards zeigen auf die LoadBalancer-IP von Traefik).

## Schritt 0: Trainer-Vorbereitung (einmalig, nicht fuer Teilnehmer)

Auf DigitalOcean (DOKS) sind Gateway-API-CRDs (v1.2.1, experimental) vorinstalliert, weil Cilium sie mitbringt.
Traefik 3.7 braucht neuere (u.a. `TLSRoute` v1 und `BackendTLSPolicy`), sonst bleibt die GatewayClass auf `Unknown`
und die Traefik-Logs zeigen `failed to list *v1.TLSRoute` / `BackendTLSPolicy`. Deshalb die CRDs aktualisieren:

```
helm template traefik-crds traefik/traefik-crds --set gatewayAPI=true | kubectl apply --server-side --force-conflicts -f -
kubectl get crd tlsroutes.gateway.networking.k8s.io -o jsonpath='{.spec.versions[*].name}'
# muss v1 enthalten
```

Kubernetes-Gateway-Provider in Traefik einschalten:

```
helm upgrade -n ingress traefik traefik/traefik --version 40.3.0 --reuse-values --skip-crds --set providers.kubernetesGateway.enabled=true
```

Pruefen, ob GatewayClass da ist und akzeptiert wurde:

```
kubectl get crd | grep gateway.networking.k8s.io
kubectl get gatewayclass
# traefik -> ACCEPTED True (dauert ggf. etwas; es gibt auf DOKS zusaetzlich die GatewayClass "cilium", die ignorieren wir)
```

Gemeinsames Gateway fuer alle Teilnehmer anlegen:

```
# vi gateway.yml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: ingress
spec:
  gatewayClassName: traefik
  listeners:
    - name: web
      port: 8000        # interner Traefik-Entrypoint "web"
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
```

```
kubectl apply -f gateway.yml
kubectl -n ingress get gateway shared-gateway
# PROGRAMMED sollte True sein, ADDRESS ist die LoadBalancer-IP von Traefik
kubectl -n ingress get pods
# es gibt weiterhin nur den einen Traefik-Pod, das Gateway erzeugt keinen neuen
```

Hinweis: Das Helm-Chart legt bei aktiviertem Provider selbst auch ein Gateway `traefik-gateway` an (nur Namespace `ingress`).
Wir nutzen `shared-gateway`, weil dort Routen aus allen Namespaces erlaubt sind.

## Schritt 1: Vorbereitung

Traegt zuerst euren Namen als Variable ein (klein, ohne Leerzeichen und Umlaute). Alle weiteren Befehle
verwenden diese Variable und koennen 1:1 kopiert werden.

```
NAME=josef
```

Wichtig: Die Variable gilt nur in dieser Terminal-Sitzung. Bei einem neuen Terminal bitte erneut setzen.

```
cd
mkdir -p manifests
cd manifests
mkdir -p gateway
cd gateway
kubectl create namespace gateway-$NAME
```

## Schritt 2: Anwendungen und Services

```
cat > 01-apple.yml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apple-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apple
  template:
    metadata:
      labels:
        app: apple
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo
          args:
            - "-text=apple-$NAME"
---
apiVersion: v1
kind: Service
metadata:
  name: apple-service
spec:
  selector:
    app: apple
  ports:
    - port: 80
      targetPort: 5678
EOF
```

```
cat > 02-banana.yml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banana-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: banana
  template:
    metadata:
      labels:
        app: banana
    spec:
      containers:
        - name: web
          image: hashicorp/http-echo
          args:
            - "-text=banana-$NAME"
---
apiVersion: v1
kind: Service
metadata:
  name: banana-service
spec:
  selector:
    app: banana
  ports:
    - port: 80
      targetPort: 5678
EOF
```

```
kubectl apply -f . -n gateway-$NAME
kubectl get pods,svc -n gateway-$NAME
```

Kurz warten, bis beide Pods `Running` sind, sonst kommt bei den ersten Requests `no available server`.

## Schritt 3: HTTPRoute mit Pfaden

```
cat > 03-httproute.yml <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
    - name: shared-gateway
      namespace: ingress
  hostnames:
    - "$NAME.app-gw.do.t3isp.de"
  rules:
    - matches:
        - path:
            type: PathPrefix
            value: /apple
      backendRefs:
        - name: apple-service
          port: 80
    - matches:
        - path:
            type: PathPrefix
            value: /banana
      backendRefs:
        - name: banana-service
          port: 80
EOF
```

```
kubectl apply -f . -n gateway-$NAME
kubectl get httproute -n gateway-$NAME
kubectl describe httproute example-route -n gateway-$NAME
```

In `describe` unter `Status > Parents` muessen die Conditions `Accepted` und `ResolvedRefs` auf `True` stehen.

## Schritt 4: Testen

```
curl http://$NAME.app-gw.do.t3isp.de/apple
curl http://$NAME.app-gw.do.t3isp.de/banana
curl http://$NAME.app-gw.do.t3isp.de/apple/foo
```

## Schritt 5: Header-Match

Nur wenn der Header `X-Version: 2` gesetzt ist, soll banana antworten, sonst apple.
Wir ueberschreiben dazu die Datei `03-httproute.yml` komplett.

```
cat > 03-httproute.yml <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
    - name: shared-gateway
      namespace: ingress
  hostnames:
    - "$NAME.app-gw.do.t3isp.de"
  rules:
    - matches:
        - headers:
            - name: X-Version
              value: "2"
      backendRefs:
        - name: banana-service
          port: 80
    - backendRefs:
        - name: apple-service
          port: 80
EOF
```

```
kubectl apply -f . -n gateway-$NAME
curl http://$NAME.app-gw.do.t3isp.de/
curl -H "X-Version: 2" http://$NAME.app-gw.do.t3isp.de/
```

Hinweis: Direkt nach dem `apply` kann der erste Request kurz `404 page not found` liefern, bis Traefik die Route
uebernommen hat. Dann einfach nach 2-3 Sekunden wiederholen.

## Schritt 6: Traffic-Splitting (Canary) per Gewichtung

Das geht mit Ingress nur ueber controller-spezifische Annotations, mit der Gateway API ist es Standard.
Wieder wird die Datei komplett ueberschrieben.

```
cat > 03-httproute.yml <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
    - name: shared-gateway
      namespace: ingress
  hostnames:
    - "$NAME.app-gw.do.t3isp.de"
  rules:
    - backendRefs:
        - name: apple-service
          port: 80
          weight: 80
        - name: banana-service
          port: 80
          weight: 20
EOF
```

```
kubectl apply -f . -n gateway-$NAME
for i in $(seq 1 20); do curl -s http://$NAME.app-gw.do.t3isp.de/; done | sort | uniq -c
```

Erwartet: ca. 80 % apple, 20 % banana (bei 20 Requests nur grob).

## Schritt 7: Fehlersuche (Route wird nicht angenommen)

```
kubectl describe httproute example-route -n gateway-$NAME
```

Typische Ursachen:

| Symptom | Ursache |
|---------|---------|
| `Accepted: False, NotAllowedByListeners` | Gateway erlaubt den Namespace nicht (`allowedRoutes`) |
| `ResolvedRefs: False, BackendNotFound` | Service-Name oder Port falsch, Request liefert `500` |
| `404 page not found` von Traefik, Status trotzdem `Accepted: True` | `parentRefs` zeigt auf ein nicht existierendes Gateway (Traefik meldet das nicht, die Route wird einfach ignoriert) oder der Hostname im Request passt nicht zu `hostnames` |
| `no available server` | Pods noch nicht bereit |

## Ingress vs. Gateway API

| Ingress | Gateway API |
|---------|-------------|
| `Ingress` (eine Ressource) | `GatewayClass` + `Gateway` + `HTTPRoute` |
| `ingressClassName: traefik` | `parentRefs` -> Gateway |
| `host` + `paths` | `hostnames` + `matches` |
| Gewichtung/Header nur per Annotation | `weight`, `headers` im Standard |
| nur HTTP(S) | zusaetzlich TCPRoute, GRPCRoute, TLSRoute |

## Aufraeumen

```
kubectl delete namespace gateway-$NAME
```

Trainer (nach dem Training):

```
kubectl -n ingress delete gateway shared-gateway
```

## Referenz

  * https://gateway-api.sigs.k8s.io/
  * https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/gateway-api/
