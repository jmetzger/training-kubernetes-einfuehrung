# Traefik errors-Middleware: eigenen HTTP-Code/Body bei Backend-Fehlern liefern

Frage aus dem Training: Kann man bei Traefik festlegen, mit welcher HTTP-Message/welchem
Statuscode geantwortet wird, wenn ein Service bzw. dessen Endpunkte nicht erreichbar sind - und
kann die Antwort dabei auch einen **anderen** Code liefern als der ursprüngliche Fehler?

**Hinweis:** Diese Übung ist noch nicht live auf einem Cluster verifiziert (siehe TEST-PFLICHT im
Skill `workshop-training`). Vor dem Einsatz im Training einmal real durchspielen und den
Beispiel-Output ersetzen.

## Wichtiger Hintergrund zuerst: 404 vs. 503 bei Traefik

Bevor man mit der `errors`-Middleware arbeitet, muss man verstehen, **wann Traefik welchen Code
liefert** - sonst testet man am falschen Fall vorbei (siehe Zusammenfassung unten, das war ein
echter Stolperstein im Training):

| Situation | Was Traefik macht | Code |
|---|---|---|
| Service-Selektor matcht **von Anfang an keine Pods** (0 Endpoints) | Traefik baut für Host/Pfad **gar keinen Router** | **404** ("no router matched" - derselbe Fall wie unbekannter Host) |
| Router existiert (Service hatte/hat Endpoints), Verbindung zum Pod schlägt fehl | Router+Service existieren, Backend nicht erreichbar | **502/503 von Traefik** |
| Pod läuft und ist erreichbar, antwortet aber selbst mit einem Fehlercode (z.B. Wartungsmodus) | Ganz normale Anfrage, Antwort kommt vom Pod | **Code vom Pod, nicht von Traefik** |

Für die `errors`-Middleware ist nur Fall 2 und 3 relevant: Die Middleware hängt an einem Router,
der tatsächlich existiert. Beim reinen 404-Fall (Zeile 1) gibt es keinen Router, an den man eine
Middleware hängen könnte - dafür bräuchte man einen separaten Catch-all-Router, der ist nicht Teil
dieser Übung.

## Step 1: Vorbereitung

```
cd
mkdir -p manifests/errors-middleware
cd manifests/errors-middleware
```

## Step 2: Backend, das erreichbar ist, aber bewusst mit 503 antwortet

Damit der Router wirklich existiert (siehe Hintergrund oben), braucht das Backend einen laufenden,
erreichbaren Pod - der antwortet einfach selbst mit 503:

```
nano broken-app.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: broken-nginx-conf
data:
  default.conf: |
    server {
      listen 80;
      location / {
        return 503 "Simulierter Ausfall\n";
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: broken-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: broken-app
  template:
    metadata:
      labels:
        app: broken-app
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          volumeMounts:
            - name: conf
              mountPath: /etc/nginx/conf.d
      volumes:
        - name: conf
          configMap:
            name: broken-nginx-conf
---
apiVersion: v1
kind: Service
metadata:
  name: broken-service
spec:
  selector:
    app: broken-app
  ports:
    - port: 80
      targetPort: 80
```

## Step 3: Ingress, der auf den Service zeigt

```
nano broken-ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: broken-ingress
spec:
  ingressClassName: traefik
  rules:
    - host: broken-<dein-name>.appv2.do.t3isp.de
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: broken-service
                port:
                  number: 80
```

```
kubectl apply -f .
```

## Step 4: Vorher testen - noch ohne Middleware

```
kubectl get endpoints broken-service
# sollte eine IP zeigen - Pod ist erreichbar

curl -i http://broken-<dein-name>.appv2.do.t3isp.de/
```

Erwartete Antwort:

```
HTTP/1.1 503 Service Unavailable
Simulierter Ausfall
```

Das ist jetzt tatsächlich der 503-Fall (Router existiert, Pod antwortet selbst mit 503) - im
Unterschied zum 404-Fall aus der Hintergrund-Tabelle.

## Step 5: Ersatz-Service bauen, der bewusst einen anderen Code liefert

```
nano fallback-page.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: fallback-nginx-conf
data:
  default.conf: |
    server {
      listen 80;
      location / {
        return 200 "Kein Backend verfuegbar - Ersatzantwort mit Code 200 statt 503\n";
        add_header Content-Type text/plain;
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fallback-page
spec:
  replicas: 1
  selector:
    matchLabels:
      app: fallback-page
  template:
    metadata:
      labels:
        app: fallback-page
    spec:
      containers:
        - name: nginx
          image: nginx:alpine
          volumeMounts:
            - name: conf
              mountPath: /etc/nginx/conf.d
      volumes:
        - name: conf
          configMap:
            name: fallback-nginx-conf
---
apiVersion: v1
kind: Service
metadata:
  name: fallback-page-svc
spec:
  selector:
    app: fallback-page
  ports:
    - port: 80
      targetPort: 80
```

Die Zeile `return 200 "...";` legt fest, mit welchem Code am Ende geantwortet wird. Für einen
anderen Code (z.B. `410 Gone`) einfach `return 410 "...";` schreiben.

```
kubectl apply -f fallback-page.yml
```

## Step 6: Middleware anlegen, die 503 abfängt

```
nano middleware.yml
```

```
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: fallback-on-503
spec:
  errors:
    status:
      - "503"
    service:
      name: fallback-page-svc
      port:
        number: 80
    query: "/"
```

```
kubectl apply -f middleware.yml
```

## Step 7: Middleware am Ingress anhängen

Ein normales `networking.k8s.io/Ingress` kennt Middlewares nicht direkt - Traefik liest sie über
eine Annotation aus. Format: `<namespace-der-middleware>-<name-der-middleware>@kubernetescrd`.

```
nano broken-ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: broken-ingress
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: <dein-namespace>-fallback-on-503@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - host: broken-<dein-name>.appv2.do.t3isp.de
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: broken-service
                port:
                  number: 80
```

```
kubectl apply -f broken-ingress.yml
```

## Step 8: Testen - Antwort sollte jetzt vom Fallback-Service kommen

```
curl -i http://broken-<dein-name>.appv2.do.t3isp.de/
```

Erwartete Antwort jetzt:

```
HTTP/1.1 200 OK
Content-Type: text/plain
...
Kein Backend verfuegbar - Ersatzantwort mit Code 200 statt 503
```

Statt `503` kommt jetzt `200` (oder der Code, den ihr in Step 5 in `return` gesetzt habt) beim
Client an - Traefik hat die komplette Antwort (Code + Body) durch die des Fallback-Service
ersetzt.

## Aufräumen

```
kubectl delete -f .
```

## Zusammenfassung

* Der ursprüngliche Fehler-Code (hier 503) ist bei Traefik **hartverdrahtet** - es gibt kein
  Config-Feld, das ihn direkt umschreibt.
* Die `errors`-Middleware fängt Antworten in einem konfigurierten Statusbereich ab und ersetzt sie
  komplett durch die Antwort eines eigenen Services.
* Welcher Code am Ende beim Client ankommt, bestimmt **der Fallback-Service selbst** (hier über
  `return 200 ...;` in der Nginx-Config) - nicht die Middleware-Konfiguration.
* Ist der Fallback-Service nicht erreichbar, fällt Traefik auf den ursprünglichen Code zurück.
* **Achtung 404 vs. 503:** Diese Middleware wirkt nur, wenn der Router überhaupt existiert. Matcht
  ein Service-Selektor von Anfang an keine Pods (0 Endpoints), baut Traefik gar keinen Router -
  das Ergebnis ist dann ein einfaches 404, an dem keine Router-gebundene Middleware greift.

## Referenzen

* [Traefik Doku: errors-Middleware](https://doc.traefik.io/traefik/reference/routing-configuration/http/middlewares/errorpages/)
* [Traefik Doku: Kubernetes Ingress - Middleware-Annotation](https://doc.traefik.io/traefik/reference/routing-configuration/kubernetes/ingress/)
* [pathtype-implementationspecific.md](pathtype-implementationspecific.md) - wie Traefik Router aus
  Ingress-Objekten baut (relevant für das Verständnis, warum ein fehlender Router keine Middleware
  durchläuft).
