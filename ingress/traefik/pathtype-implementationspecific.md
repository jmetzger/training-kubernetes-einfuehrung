# Ingress pathType: ImplementationSpecific bei Traefik

Frage aus dem Training: Wie verhält sich `pathType: ImplementationSpecific` bei Traefik konkret,
im Unterschied zu `Prefix` und `Exact`?

Kurze Antwort vorab (Details und Beleg weiter unten):

* Laut Kubernetes-Spec ist `ImplementationSpecific` **nicht spezifiziert** — jeder
  Ingress-Controller darf hier selbst entscheiden, wie er matcht.
* `Prefix` ist dagegen spezifiziert: Kubernetes verlangt Pfadsegment-Grenzen
  (`/apple` matcht `/apple`, `/apple/`, `/apple/foo`, aber **nicht** `/applebee`).
* Traefik übersetzt intern **beide** pathTypes (`Prefix` UND `ImplementationSpecific`) auf
  denselben Router-Matcher `PathPrefix(...)`. Und dieser Matcher macht standardmäßig einen
  reinen String-Präfix-Vergleich **ohne** Segmentgrenze — d.h. `/apple` matcht auch `/applebee`.
  In der Praxis verhalten sich `Prefix` und `ImplementationSpecific` bei Traefik also **identisch**,
  und keiner von beiden folgt standardmäßig der Kubernetes-Spec für `Prefix`.

Das testen wir jetzt live.

## Step 1: Walkthrough - Deployment und Service

```
cd
mkdir -p manifests
cd manifests
mkdir pathtype
cd pathtype
```

```
nano apple-deploy.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apple-app
  labels:
    app: apple
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
            - "-text=apple-<euer-name>"
```

```
nano apple-svc.yaml
```

```
kind: Service
apiVersion: v1
metadata:
  name: apple-service
spec:
  type: ClusterIP
  selector:
    app: apple
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5678 # Default port for image
```

```
kubectl apply -f .
```

## Step 2: Walkthrough - Ingress mit Prefix und ImplementationSpecific nebeneinander

Damit wir die beiden pathTypes direkt vergleichen können, bauen wir zwei Hosts auf
demselben Ingress, die auf denselben Pfad `/apple` und denselben Service zeigen -
einmal mit `pathType: Prefix`, einmal mit `pathType: ImplementationSpecific`.

```
nano ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pathtype-ingress
spec:
  ingressClassName: traefik
  rules:
  - host: "prefix-<euername>.apppathtype.do.t3isp.de"
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service:
              name: apple-service
              port:
                number: 80
  - host: "implspec-<euername>.apppathtype.do.t3isp.de"
    http:
      paths:
        - path: /apple
          pathType: ImplementationSpecific
          backend:
            service:
              name: apple-service
              port:
                number: 80
```

```
kubectl apply -f ingress.yml
kubectl describe ingress pathtype-ingress
```

## Step 3: Testing - matcht /applebee bei Prefix wirklich anders als bei ImplementationSpecific?

Wir testen für beide Hosts dieselben vier Pfade: `/apple`, `/apple/`, `/apple/foo` (sollten laut
Spec bei `Prefix` alle matchen) und `/applebee` (sollte laut Spec bei `Prefix` **nicht** matchen,
weil `bee` kein eigenes Pfadsegment ist, sondern einfach an `apple` drangehängt).

```
# Host mit pathType: Prefix
curl http://prefix-<euername>.apppathtype.do.t3isp.de/apple
curl http://prefix-<euername>.apppathtype.do.t3isp.de/apple/
curl http://prefix-<euername>.apppathtype.do.t3isp.de/apple/foo
curl http://prefix-<euername>.apppathtype.do.t3isp.de/applebee
```

```
# Host mit pathType: ImplementationSpecific
curl http://implspec-<euername>.apppathtype.do.t3isp.de/apple
curl http://implspec-<euername>.apppathtype.do.t3isp.de/apple/
curl http://implspec-<euername>.apppathtype.do.t3isp.de/apple/foo
curl http://implspec-<euername>.apppathtype.do.t3isp.de/applebee
```

Ergebnis: **Alle acht curls liefern `apple-<euer-name>` zurück** - inklusive `/applebee` bei
beiden Hosts. Traefik unterscheidet hier standardmäßig gar nicht zwischen `Prefix` und
`ImplementationSpecific`. Das ist kein Trainingsfehler, sondern dokumentiertes Traefik-Verhalten
(siehe Referenzen unten): Traefik matcht `PathPrefix` per einfachem String-Vergleich
(`strings.HasPrefix`), ohne auf Pfadsegment-Grenzen zu achten.

## Step 4: Bonus - echtes Kubernetes-konformes Prefix-Matching aktivieren

Seit Traefik v3.5 gibt es dafür die Provider-Option `strictPrefixMatching` (per Default `false`).
Aktiviert man sie in den Helm-Values des Traefik-Providers, matcht `PathPrefix` dann
Kubernetes-konform pfadsegmentweise - und zwar für **beide** pathTypes gleichermaßen, weil Traefik
intern weiterhin nicht zwischen `Prefix` und `ImplementationSpecific` unterscheidet:

```yaml
# traefik helm values.yaml (Auszug)
additionalArguments:
  - "--providers.kubernetesingress.strictprefixmatching=true"
```

```
helm upgrade -n ingress traefik traefik/traefik --version 40.3.0 --reuse-values -f values.yaml
```

Mit aktiviertem `strictPrefixMatching` würde `/applebee` bei beiden Hosts aus Step 3 **nicht**
mehr matchen (404), `/apple`, `/apple/` und `/apple/foo` weiterhin schon.

## Fazit

* `pathType: Exact` -> Traefik-Matcher `Path(...)` (exakter Treffer, siehe
  [04-ingress-traefik-with-hostnames-deployment.md](/kubectl-examples/04-ingress-traefik-with-hostnames-deployment.md)).
* `pathType: Prefix` **und** `pathType: ImplementationSpecific` -> beide landen bei Traefik auf
  demselben Matcher `PathPrefix(...)`, der standardmäßig ein reiner String-Präfix-Vergleich ohne
  Segmentgrenze ist. Kubernetes-konformes Verhalten für `Prefix` gibt es bei Traefik nur als Opt-in
  über `strictPrefixMatching`.
* Für Teilnehmer heißt das praktisch: Verlasst euch bei Traefik nicht darauf, dass `pathType: Prefix`
  automatisch an Pfadsegmenten stoppt - testet es wie in Step 3, oder aktiviert `strictPrefixMatching`
  wenn ihr euch auf die Kubernetes-Spec verlassen wollt.

## Referenzen

* [Kubernetes Ingress: Path types (Exact, Prefix, ImplementationSpecific)](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)
* [Traefik Doku: Kubernetes Ingress Provider - `strictPrefixMatching`](https://doc.traefik.io/traefik/reference/install-configuration/providers/kubernetes/kubernetes-ingress/)
* [Traefik Doku: Kubernetes Ingress Routing Configuration](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/ingress/)
* [GitHub Issue traefik/traefik #11200: Prefix-Matching entsprach nicht der Kubernetes-Spec](https://github.com/traefik/traefik/issues/11200)
* [GitHub PR traefik/traefik #11203: Einführung von `strictPrefixMatching`](https://github.com/traefik/traefik/pull/11203)
* Quellcode zum Nachvollziehen (Version dieses Trainings, Chart 40.3.0 = Traefik v3.7.4):
  [`pkg/provider/kubernetes/ingress/kubernetes.go`](https://github.com/traefik/traefik/blob/v3.7.4/pkg/provider/kubernetes/ingress/kubernetes.go)
  (Funktionen `loadRouter` und `buildRule`) und
  [`pkg/muxer/http/matcher.go`](https://github.com/traefik/traefik/blob/v3.7.4/pkg/muxer/http/matcher.go)
  (Funktion `pathPrefix`, macht `strings.HasPrefix(req.URL.Path, path)`).
