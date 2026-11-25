# Gateway API mit Traefik (Ergaenzung zu Ingress)

## Hintergrund

Die Gateway API ist der Nachfolger von Ingress. Statt einer einzigen Ressource gibt es Rollen-getrennte Objekte:

| Ressource | Wer pflegt sie? | Aufgabe |
|-----------|-----------------|---------|
| GatewayClass | Infrastruktur-Anbieter | Welcher Controller (hier: Traefik) |
| Gateway | Cluster-Betreiber (Trainer) | Listener: Port, Protokoll, welche Namespaces duerfen anhaengen |
| HTTPRoute | Anwendungsentwickler (Teilnehmer) | Hostnamen, Pfade, Backends, Gewichtung |

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
```

Hinweis: Das Helm-Chart legt bei aktiviertem Provider selbst auch ein Gateway `traefik-gateway` an (nur Namespace `ingress`).
Wir nutzen `shared-gateway`, weil dort Routen aus allen Namespaces erlaubt sind.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir gateway
cd gateway
```

```
kubectl create namespace gateway-<dein-name>
```

## Schritt 2: Anwendungen und Services

```
# vi 01-apple.yml
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
            - "-text=apple-<dein-name>"
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
```

```
# vi 02-banana.yml
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
            - "-text=banana-<dein-name>"
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
```

```
kubectl apply -f . -n gateway-<dein-name>
kubectl get pods,svc -n gateway-<dein-name>
```

Kurz warten, bis beide Pods `Running` sind, sonst kommt bei den ersten Requests `no available server`.

## Schritt 3: HTTPRoute mit Pfaden

```
# vi 03-httproute.yml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: example-route
spec:
  parentRefs:
    - name: shared-gateway
      namespace: ingress
  hostnames:
    - "<dein-name>.app-gw.do.t3isp.de"
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
```

```
kubectl apply -f . -n gateway-<dein-name>
kubectl get httproute -n gateway-<dein-name>
kubectl describe httproute example-route -n gateway-<dein-name>
```

In `describe` unter `Status > Parents` muessen die Conditions `Accepted` und `ResolvedRefs` auf `True` stehen.

## Schritt 4: Testen

```
curl http://<dein-name>.app-gw.do.t3isp.de/apple
curl http://<dein-name>.app-gw.do.t3isp.de/banana
curl http://<dein-name>.app-gw.do.t3isp.de/apple/foo
```

## Schritt 5: Header-Match

Nur wenn der Header `X-Version: 2` gesetzt ist, soll banana antworten, sonst apple.

```
# vi 03-httproute.yml  (Rules ersetzen)
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
```

```
kubectl apply -f . -n gateway-<dein-name>
curl http://<dein-name>.app-gw.do.t3isp.de/
curl -H "X-Version: 2" http://<dein-name>.app-gw.do.t3isp.de/
```

## Schritt 6: Traffic-Splitting (Canary) per Gewichtung

Das geht mit Ingress nur ueber controller-spezifische Annotations, mit der Gateway API ist es Standard.

```
# vi 03-httproute.yml  (Rules ersetzen)
  rules:
    - backendRefs:
        - name: apple-service
          port: 80
          weight: 80
        - name: banana-service
          port: 80
          weight: 20
```

```
kubectl apply -f . -n gateway-<dein-name>
for i in $(seq 1 20); do curl -s http://<dein-name>.app-gw.do.t3isp.de/; done | sort | uniq -c
```

Erwartet: ca. 80 % apple, 20 % banana (bei 20 Requests nur grob).

## Schritt 7: Fehlersuche (Route wird nicht angenommen)

```
kubectl describe httproute example-route -n gateway-<dein-name>
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
kubectl delete namespace gateway-<dein-name>
```

Trainer (nach dem Training):

```
kubectl -n ingress delete gateway shared-gateway
```

## Referenz

  * https://gateway-api.sigs.k8s.io/
  * https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/gateway-api/
