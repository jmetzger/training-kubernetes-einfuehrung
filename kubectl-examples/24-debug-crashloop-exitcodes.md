# Debugging: CrashLoopBackOff, aber die Logs sind sauber - Exit Codes lesen

## Hintergrund

Bisher hat euch bei einem `CrashLoopBackOff` immer `kubectl logs` gerettet:
Irgendwo stand ein `[emerg]` oder `[ERROR]`, und damit war die Ursache klar.

Es gibt aber Faelle, in denen die Logs voellig unauffaellig sind - der Prozess
hat gar keine Gelegenheit, einen Fehler zu schreiben, oder er ist aus seiner
Sicht ganz normal fertig. Dann hilft nur der Blick auf **wie** der Container
beendet wurde: `Reason` und `Exit Code` unter `Last State` in
`kubectl describe`.

| Exit Code | Bedeutung | Typische Ursache |
|-----------|-----------|------------------|
| `0` | Prozess hat sich selbst normal beendet | Prozess ist kein Vordergrund-Prozess (Daemon), Skript ist einfach fertig |
| `1` | Prozess hat sich mit Fehler beendet | Anwendungsfehler - steht in den Logs |
| `137` | Prozess wurde von aussen mit `SIGKILL` (9) getoetet: 128 + 9 | `OOMKilled` (Memory-Limit) oder Liveness-Probe fehlgeschlagen |
| `139` | Segmentation Fault: 128 + 11 | Bug im Programm oder in einer Bibliothek |
| `143` | Prozess wurde mit `SIGTERM` (15) beendet: 128 + 15 | Normales Herunterfahren durch Kubernetes |

Merkregel: Alles ueber 128 heisst "ein Signal hat den Prozess beendet" -
Exit Code minus 128 ist die Signalnummer.

In dieser Uebung lauft ihr in zwei dieser Faelle. Beide Pods landen im
`CrashLoopBackOff`, beide Logs sehen gesund aus.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 24-debug-crashloop-exitcodes
cd 24-debug-crashloop-exitcodes
```

## Schritt 2: Zwei Deployments anlegen

Beide Manifeste funktionieren absichtlich nicht.

Das erste ist eine kleine Python-Anwendung, die beim Start Daten in einen
Cache im Arbeitsspeicher laedt.

```
nano 01-cache-app.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cache-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: cache-app
  template:
    metadata:
      labels:
        app: cache-app
    spec:
      containers:
      - name: cache-app
        image: python:3.12-slim
        command: ["python", "-u", "-c"]
        args:
        - |
          import time
          print("cache-app startet, lade Daten in den Cache ...")
          cache = []
          for i in range(20):
              cache.append(bytearray(10 * 1024 * 1024))
              print(f"{(i+1)*10} MB geladen")
              time.sleep(0.5)
          print("Cache geladen, bereit")
          while True:
              time.sleep(60)
        resources:
          requests:
            memory: "32Mi"
          limits:
            memory: "64Mi"
```

Das zweite ist ein nginx, bei dem jemand den Startbefehl explizit ins
Manifest geschrieben hat.

```
nano 02-web.yml
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
        command: ["nginx"]
        ports:
        - containerPort: 80
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
kubectl create ns crash-<dein-name>
kubectl apply -f . -n crash-<dein-name>
```

## Schritt 3: Symptom beobachten

```
kubectl get pods -n crash-<dein-name>
```

**Erwartete Ausgabe** (nach ca. 1 Minute; die Status wechseln jeweils mit `CrashLoopBackOff` ab):

```
NAME                         READY   STATUS      RESTARTS      AGE
cache-app-5d46df6f49-s5wh2   0/1     OOMKilled   3 (48s ago)   73s
web-55f497cf86-ntgh2         0/1     Completed   3 (60s ago)   73s
```

Schaut genau hin: Die `STATUS`-Spalte zeigt zwischendurch nicht nur
`CrashLoopBackOff`, sondern auch `OOMKilled` bzw. `Completed`. Das ist
bereits der erste Hinweis.

## Schritt 4: Aufgabe - beide Pods nach Running bringen

Findet fuer beide Deployments heraus, warum der Container immer wieder
beendet wird, und behebt es. Am Ende muss `cache-app` in den Logs
`Cache geladen, bereit` melden und `curl http://web` die nginx-Startseite liefern.

Fangt mit den Logs an - und wundert euch nicht, wenn ihr dort nichts findet.
Dann geht es weiter mit:

```
kubectl describe pod -n crash-<dein-name> <pod> | grep -A6 "Last State"
```

Praktischer Einzeiler, der `Reason` und `Exit Code` fuer alle Pods im
Namespace zeigt:

```
kubectl get pods -n crash-<dein-name> -o custom-columns='NAME:.metadata.name,LAST-REASON:.status.containerStatuses[0].lastState.terminated.reason,EXIT:.status.containerStatuses[0].lastState.terminated.exitCode,RESTARTS:.status.containerStatuses[0].restartCount'
```

```
NAME                         LAST-REASON   EXIT   RESTARTS
cache-app-5d46df6f49-s5wh2   OOMKilled     137    4
web-55f497cf86-ntgh2         Completed     0      4
```

<details>
<summary>Hinweis 1: cache-app - die Logs hoeren einfach auf</summary>

```
kubectl logs -n crash-<dein-name> deploy/cache-app
```

```
cache-app startet, lade Daten in den Cache ...
10 MB geladen
20 MB geladen
30 MB geladen
40 MB geladen
50 MB geladen
```

Kein Fehler, kein Traceback, keine letzte Zeile - das Log bricht mitten im
Laden ab. Das ist typisch fuer einen Prozess, der von aussen **getoetet**
wurde: Er konnte nichts mehr schreiben.

```
kubectl describe pod -n crash-<dein-name> -l app=cache-app | grep -B2 -A12 "Last State"
```

```
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
    ...
    Limits:
      memory:  64Mi
    Requests:
      memory:  32Mi
```

`OOMKilled` (Out Of Memory) mit Exit Code `137` = 128 + 9 = `SIGKILL`. Der
Kernel hat den Prozess abgeschossen, weil er mehr Speicher wollte als das
Limit von `64Mi` erlaubt. Die Anwendung hat bei 50 MB Nutzdaten plus dem
Python-Interpreter selbst das Limit gerissen - sie will aber 200 MB laden.

</details>

<details>
<summary>Hinweis 2: web - die Logs sehen perfekt aus</summary>

```
kubectl logs -n crash-<dein-name> deploy/web
```

```
2026/09/25 10:03:11 [notice] 1#1: using the "epoll" event method
2026/09/25 10:03:11 [notice] 1#1: nginx/1.27.5
2026/09/25 10:03:11 [notice] 1#1: OS: Linux 6.12.96+deb13-amd64
2026/09/25 10:03:11 [notice] 8#8: start worker processes
```

nginx startet, startet Worker - alles gut. Und trotzdem:

```
kubectl describe pod -n crash-<dein-name> -l app=web | grep -A4 "Last State"
```

```
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
```

Exit Code `0`, `Completed`: Der Prozess hat sich **selbst** normal beendet.
Kubernetes sieht nur: PID 1 im Container ist weg, also starte ich den
Container neu. Achtet auf die Log-Zeile `8#8: start worker processes` - die
Worker wurden von Prozess 8 gestartet, nicht von Prozess 1.

Was macht `nginx` ohne weitere Optionen? Es **daemonisiert**: Der
Startprozess (PID 1) forkt den eigentlichen Server in den Hintergrund und
beendet sich mit Exit Code 0. Auf einem normalen Server ist das gewollt -
in einem Container ist der Container damit fertig, denn ein Container lebt
genau so lange wie sein Prozess mit PID 1.

Vergleicht mit dem, was das Image selbst als Startbefehl vorsieht:

```
kubectl run nginx-inspect --image=nginx:1.27 --restart=Never -n crash-<dein-name> --dry-run=client -o yaml > /dev/null
docker inspect nginx:1.27 --format '{{.Config.Cmd}}'
```

Falls kein `docker` vorhanden ist: Der Standard-`CMD` des nginx-Images lautet
`nginx -g "daemon off;"`.

</details>

<details>
<summary>Loesung</summary>

**cache-app:** Memory-Limit passend zum tatsaechlichen Bedarf setzen. Die App
laedt 200 MB, plus Interpreter - `256Mi` reicht.

```
nano 01-cache-app.yml
```

```
        resources:
          requests:
            memory: "32Mi"
          limits:
            memory: "256Mi"
```

**web:** nginx im Vordergrund laufen lassen. Entweder die `command`-Zeile
ganz entfernen (dann gilt der `CMD` aus dem Image) oder explizit:

```
nano 02-web.yml
```

```
        command: ["nginx", "-g", "daemon off;"]
```

```
kubectl apply -f . -n crash-<dein-name>
kubectl get pods -n crash-<dein-name>
```

```
NAME                         READY   STATUS    RESTARTS   AGE
cache-app-566bfbd7c6-8tbqt   1/1     Running   0          28s
web-576c4c5d6d-wv5jv         1/1     Running   0          20s
```

</details>

## Schritt 5: Loesung pruefen

```
kubectl logs -n crash-<dein-name> deploy/cache-app | tail -2
kubectl logs -n crash-<dein-name> deploy/web | tail -2
```

```
200 MB geladen
Cache geladen, bereit

2026/09/25 10:04:46 [notice] 1#1: start worker process 7
2026/09/25 10:04:46 [notice] 1#1: start worker process 8
```

Bei nginx starten die Worker jetzt von `1#1` aus - PID 1 ist der
nginx-Master und bleibt am Leben.

```
kubectl run curl-test --rm -i --restart=Never -n crash-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s http://web
```

**Erwartete Ausgabe:** die nginx-Startseite mit `<h1>Welcome to nginx!</h1>`.

Wer einen Metrics-Server im Cluster hat, kann den echten Verbrauch der
cache-app jetzt sehen:

```
kubectl top pod -n crash-<dein-name>
```

## Aufraeumen

```
kubectl delete namespace crash-<dein-name>
```

## Zusammenfassung

| Pod | `STATUS` zwischendurch | `Last State` | Exit Code | Logs | Ursache | Fix |
|-----|------------------------|--------------|-----------|------|---------|-----|
| cache-app | `OOMKilled` | `OOMKilled` | `137` | brechen ohne Fehler ab | Memory-Limit `64Mi` zu klein fuer 200 MB Cache | Limit auf `256Mi` |
| web | `Completed` | `Completed` | `0` | sehen normal aus | `nginx` daemonisiert, PID 1 beendet sich | `nginx -g "daemon off;"` oder `command` entfernen |

**Merkhilfe:** Sind die Logs sauber, frag nach dem Exit Code. `0` heisst
"der Prozess ist freiwillig gegangen" - meist ein Vordergrund-Problem.
`137` heisst "jemand hat ihn erschossen" - meist `OOMKilled`, sonst die
Liveness-Probe (steht dann in den Events).
