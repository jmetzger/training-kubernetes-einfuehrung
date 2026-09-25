# Debugging: Pod laeuft, Anwendung kaputt - Fehler nur in den Logs sichtbar

## Hintergrund

In der vorherigen Debugging-Uebung hat Kubernetes euch den Fehler quasi
hinterhergetragen: `CrashLoopBackOff`, `Exit Code: 1`, Restarts - jeder sieht
sofort, dass etwas nicht stimmt.

Der haeufigere Fall in der Praxis ist unangenehmer: Der Pod ist `Running`,
`1/1 Ready`, `kubectl describe` zeigt keine Warnung, der Service hat Endpoints -
und trotzdem liefert die Anwendung Fehler. Kubernetes weiss nichts davon, weil
der Prozess ja laeuft. Der einzige Ort, an dem der Fehler steht, sind die Logs
der Anwendung.

| Was Kubernetes sieht | Was der Benutzer sieht | Wo der Grund steht |
|----------------------|------------------------|--------------------|
| Pod `Running`, `1/1 Ready` | `403 Forbidden`, `502 Bad Gateway` | nur in `kubectl logs` |

In dieser Uebung baut ihr eine kleine Website (nginx) mit einem `/api/`-Pfad,
der an ein Backend weitergereicht wird. Beides ist kaputt - und keiner der
beiden Fehler taucht in `kubectl get` oder `kubectl describe` auf.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 23-debug-fehler-nur-in-logs
cd 23-debug-fehler-nur-in-logs
```

## Schritt 2: Backend anlegen

Das Backend ist ein minimaler Python-HTTP-Server, der auf Port 8080 ein
Verzeichnis-Listing ausliefert.

Achtung: In diesem Manifest steckt einer der beiden Fehler.

```
nano 01-backend.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: python:3.12-slim
        command: ["python", "-m", "http.server", "8080"]
        ports:
        - containerPort: 8080
---
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
```

## Schritt 3: Website-Inhalt und nginx-Konfiguration anlegen

Der Inhalt der Website kommt aus einer ConfigMap. Achtung: Auch hier steckt
ein Fehler.

```
nano 02-web-content.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.htm: |
    <html>
    <body>
    <h1>Hallo vom Kubernetes-Training</h1>
    <p>Backend-Status: <a href="/api/">/api/</a></p>
    </body>
    </html>
```

Die nginx-Konfiguration liefert unter `/` den Inhalt aus und reicht `/api/`
an das Backend weiter (Reverse Proxy). Diese Datei ist in Ordnung.

```
nano 03-web-nginx-conf.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-nginx-conf
data:
  default.conf: |
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html;
        }

        location /api/ {
            proxy_pass http://backend-svc/;
        }
    }
```

## Schritt 4: Website-Deployment und Service anlegen

Dieses Manifest ist in Ordnung.

```
nano 04-web.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
        volumeMounts:
        - name: content
          mountPath: /usr/share/nginx/html
        - name: conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      volumes:
      - name: content
        configMap:
          name: web-content
      - name: conf
        configMap:
          name: web-nginx-conf
---
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

```
kubectl create ns logs-<dein-name>
kubectl apply -f . -n logs-<dein-name>
```

## Schritt 5: Aus Kubernetes-Sicht ist alles in Ordnung

```
kubectl get pods -n logs-<dein-name>
kubectl get endpoints -n logs-<dein-name>
kubectl describe pod -n logs-<dein-name> -l app=web | grep -A10 "^Events:"
```

**Erwartete Ausgabe:**

```
NAME                       READY   STATUS    RESTARTS   AGE
backend-6bfb7b6785-snlc6   1/1     Running   0          30s
web-7dd7bd48b9-gsjqm       1/1     Running   0          30s

NAME          ENDPOINTS        AGE
backend-svc   10.244.0.2:80    31s
web           10.244.0.54:80   30s

Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  31s   default-scheduler  Successfully assigned ...
  Normal  Pulled     31s   kubelet            Container image "nginx:1.27" already present on machine
  Normal  Created    31s   kubelet            Container created
  Normal  Started    31s   kubelet            Container started
```

Beide Pods `Running`, beide `Ready`, beide Services haben Endpoints, keine
einzige Warnung. Kubernetes ist zufrieden.

## Schritt 6: Der Benutzer ist nicht zufrieden

Testet die Website aus einem Wegwerf-Pod heraus:

```
kubectl run curl-test --rm -i --restart=Never -n logs-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s -w "\nHTTP %{http_code}\n" http://web/
```

```
kubectl run curl-test --rm -i --restart=Never -n logs-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s -w "\nHTTP %{http_code}\n" http://web/api/
```

**Erwartete Ausgabe:**

```
<html>
<head><title>403 Forbidden</title></head>
...
HTTP 403
```

```
<html>
<head><title>502 Bad Gateway</title></head>
...
HTTP 502
```

Die Startseite liefert `403 Forbidden`, der API-Pfad `502 Bad Gateway`.

## Schritt 7: Aufgabe - beide Fehler finden

Findet beide Ursachen und behebt sie. Am Ende muss `curl http://web/` die
Seite mit `Hallo vom Kubernetes-Training` liefern und `curl http://web/api/`
das Verzeichnis-Listing des Backends (`HTTP 200`).

Euer Werkzeug ist diesmal vor allem `kubectl logs`. Nuetzliche Varianten:

```
kubectl logs -n logs-<dein-name> deploy/web
kubectl logs -n logs-<dein-name> deploy/web --tail=20
kubectl logs -n logs-<dein-name> deploy/web -f
kubectl logs -n logs-<dein-name> -l app=web
kubectl logs -n logs-<dein-name> deploy/web --since=5m
```

Tipp: Oeffnet ein zweites Terminal mit `kubectl logs -f` und schickt im
ersten Terminal die `curl`-Anfragen ab. So seht ihr live, was nginx zu jeder
Anfrage schreibt.

<details>
<summary>Hinweis 1: Fehler 1 - was steht zum 403 in den Logs?</summary>

```
kubectl logs -n logs-<dein-name> deploy/web --tail=20
```

```
2026/09/25 09:40:59 [error] 20#20: *1 directory index of "/usr/share/nginx/html/" is forbidden, client: 10.244.0.45, server: localhost, request: "GET / HTTP/1.1", host: "web"
10.244.0.45 - - [25/Sep/2026:09:40:59 +0000] "GET / HTTP/1.1" 403 153 "-" "curl/8.10.1" "-"
```

nginx schreibt zwei Arten von Zeilen: das **Error-Log** (`[error]`, mit
Grund) und das **Access-Log** (eine Zeile pro Anfrage mit HTTP-Status).

`directory index of "/usr/share/nginx/html/" is forbidden` heisst: nginx hat
im Verzeichnis keine `index.html` gefunden und darf ohne Index-Datei kein
Verzeichnis-Listing zeigen. Also: Was liegt in dem Verzeichnis?

```
kubectl exec -n logs-<dein-name> deploy/web -- ls -l /usr/share/nginx/html
```

```
lrwxrwxrwx 1 root root 16 Sep 25 09:40 index.htm -> ..data/index.htm
```

Die Datei heisst `index.htm` - nginx sucht `index.html`. Der Tippfehler steckt
im Key der ConfigMap `web-content`.

</details>

<details>
<summary>Hinweis 2: Fehler 2 - was steht zum 502 in den Logs?</summary>

```
2026/09/25 09:41:02 [error] 21#21: *2 connect() failed (111: Connection refused) while connecting to upstream, client: 10.244.0.66, server: localhost, request: "GET /api/ HTTP/1.1", upstream: "http://10.245.229.205:80/", host: "web"
10.244.0.66 - - [25/Sep/2026:09:41:02 +0000] "GET /api/ HTTP/1.1" 502 157 "-" "curl/8.10.1" "-"
```

`connect() failed (111: Connection refused) while connecting to upstream` -
nginx hat versucht, das Backend zu erreichen, und wurde abgewiesen. Die
Log-Zeile verraet sogar, wohin: `upstream: "http://10.245.229.205:80/"`. Das
ist die ClusterIP von `backend-svc`, Port 80.

Der Service leitet Port 80 weiter - aber wohin? Und auf welchem Port lauscht
der Backend-Container wirklich?

```
kubectl get endpoints backend-svc -n logs-<dein-name>
kubectl get pods -n logs-<dein-name> -l app=backend -o jsonpath='{.items[0].spec.containers[0].ports}'
kubectl logs -n logs-<dein-name> deploy/backend
```

Die Endpoints zeigen `10.244.0.2:80`, der Container lauscht auf `8080`. Das
Backend-Log ist leer - dort ist nie eine Anfrage angekommen. Fehler: `targetPort`
im Service `backend-svc`.

</details>

<details>
<summary>Loesung</summary>

**Fehler 1:** Key in der ConfigMap `web-content` von `index.htm` auf `index.html`
aendern:

```
nano 02-web-content.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-content
data:
  index.html: |
    <html>
    <body>
    <h1>Hallo vom Kubernetes-Training</h1>
    <p>Backend-Status: <a href="/api/">/api/</a></p>
    </body>
    </html>
```

**Fehler 2:** `targetPort` im Service `backend-svc` von `80` auf `8080` aendern:

```
nano 01-backend.yml
```

```
...
apiVersion: v1
kind: Service
metadata:
  name: backend-svc
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
```

```
kubectl apply -f . -n logs-<dein-name>
```

**Achtung, Geduld:** Eine geaenderte ConfigMap, die als Volume gemountet ist,
wird vom Kubelet erst nach bis zu einer Minute im Pod aktualisiert - ohne
Neustart des Pods. Wer nicht warten will:

```
kubectl rollout restart deploy/web -n logs-<dein-name>
```

Kontrolle, ob die Datei jetzt richtig heisst:

```
kubectl exec -n logs-<dein-name> deploy/web -- ls /usr/share/nginx/html
```

```
index.html
```

</details>

## Schritt 8: Loesung pruefen

```
kubectl run curl-test --rm -i --restart=Never -n logs-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s -w "\nHTTP %{http_code}\n" http://web/
```

```
kubectl run curl-test --rm -i --restart=Never -n logs-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s -w "\nHTTP %{http_code}\n" http://web/api/
```

**Erwartete Ausgabe:**

```
<h1>Hallo vom Kubernetes-Training</h1>
...
HTTP 200
```

```
<title>Directory listing for /</title>
...
HTTP 200
```

Und in den Logs sehen jetzt beide Seiten gut aus - nginx mit `200` im
Access-Log, und das Backend bekommt endlich Anfragen:

```
kubectl logs -n logs-<dein-name> deploy/web --tail=2
kubectl logs -n logs-<dein-name> deploy/backend
```

```
10.244.0.107 - - [25/Sep/2026:09:42:32 +0000] "GET / HTTP/1.1" 200 118 "-" "curl/8.10.1" "-"
10.244.0.103 - - [25/Sep/2026:09:42:39 +0000] "GET /api/ HTTP/1.1" 200 832 "-" "curl/8.10.1" "-"

10.244.0.54 - - [25/Sep/2026 09:42:39] "GET / HTTP/1.0" 200 -
```

## Aufraeumen

```
kubectl delete namespace logs-<dein-name>
```

## Zusammenfassung

| Symptom | `kubectl get` / `describe` | Log-Zeile | Ursache | Fix |
|---------|---------------------------|-----------|---------|-----|
| `403 Forbidden` auf `/` | alles gruen | `directory index of "/usr/share/nginx/html/" is forbidden` | ConfigMap-Key `index.htm` statt `index.html` | Key umbenennen |
| `502 Bad Gateway` auf `/api/` | alles gruen | `connect() failed (111: Connection refused) while connecting to upstream ... upstream: "http://<ClusterIP>:80/"` | `targetPort: 80`, Container lauscht auf 8080 | `targetPort: 8080` |

**Merkhilfe:** `Running` heisst nur "der Prozess lebt", nicht "die Anwendung
funktioniert". Wenn Kubernetes gruen ist und der Benutzer rot sieht, sind die
Logs der einzige Zeuge. Und: Ohne Readiness-Probe faellt so ein Fehler
Kubernetes nie auf - mit einer Probe auf `/` waere der Pod bei Fehler 1 gar
nicht erst `Ready` geworden.
