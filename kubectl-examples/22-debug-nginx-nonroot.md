# Debugging: nginx als Nicht-Root-User startet nicht (CrashLoopBackOff)

## Hintergrund

Aus Sicherheitsgruenden sollen Container nicht als root laufen. Ueber den
`securityContext` kann man Kubernetes anweisen, den Prozess im Container mit
einer anderen User-ID zu starten - und mit `runAsNonRoot: true` sogar erzwingen,
dass er niemals als root laeuft.

| Feld | Bedeutung |
|------|-----------|
| `runAsUser: 1000` | Prozess laeuft mit UID 1000 statt root (UID 0) |
| `runAsGroup: 1000` | Prozess laeuft mit GID 1000 |
| `runAsNonRoot: true` | Kubelet verweigert den Start, wenn der Prozess als UID 0 laufen wuerde |

Das Problem: Viele Standard-Images (z.B. `nginx`) gehen davon aus, dass sie als
root starten. Sie schreiben in Verzeichnisse, die root gehoeren, oder binden
privilegierte Ports (< 1024). Setzt man dann per `securityContext` einen anderen
User, crasht der Container - und man muss herausfinden, warum.

Genau das ist die Uebung: Ihr bekommt ein kaputtes Manifest und sollt den
Fehler mit `kubectl describe`, `kubectl logs` und `kubectl exec` selbst finden
und beheben.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 22-debug-nginx-nonroot
cd 22-debug-nginx-nonroot
```

## Schritt 2: Deployment und Service anlegen

Achtung: Dieses Manifest funktioniert absichtlich nicht.

```
nano 01-deployment.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-nonroot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-nonroot
  template:
    metadata:
      labels:
        app: nginx-nonroot
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        runAsNonRoot: true
      containers:
      - name: nginx
        image: nginx:1.30
        ports:
        - containerPort: 80
```

```
nano 02-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-nonroot
spec:
  selector:
    app: nginx-nonroot
  ports:
  - port: 80
    targetPort: 80
```

```
kubectl create ns debug-<dein-name>
kubectl apply -f . -n debug-<dein-name>
```

## Schritt 3: Symptom beobachten

```
kubectl get pods -n debug-<dein-name>
```

**Erwartete Ausgabe** (nach ca. 1 Minute, der Status wechselt zwischen `Error` und `CrashLoopBackOff`):

```
NAME                             READY   STATUS             RESTARTS      AGE
nginx-nonroot-8cf677d9b-x2g5f    0/1     CrashLoopBackOff   3 (41s ago)   62s
```

Der Service hat keine Endpoints, weil der Pod nie `Ready` wird:

```
kubectl get endpoints nginx-nonroot -n debug-<dein-name>
```

```
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME            ENDPOINTS   AGE
nginx-nonroot               1m
```

Die Warnung koennt ihr ignorieren - entscheidend ist die leere Spalte
`ENDPOINTS` (auf aelteren Clustern steht dort `<none>`).

## Schritt 4: Aufgabe - Fehler selbst finden

Findet heraus, **warum** der Container abstuerzt, und bringt den Pod nach
`Running`. Am Ende muss ein `curl` gegen den Service die nginx-Startseite liefern.

Eure Werkzeuge:

```
kubectl describe pod -n debug-<dein-name> -l app=nginx-nonroot
kubectl logs -n debug-<dein-name> deploy/nginx-nonroot
kubectl logs -n debug-<dein-name> deploy/nginx-nonroot --previous
kubectl exec -n debug-<dein-name> <pod> -- <befehl>
```

Zwei Loesungswege sind erlaubt:

* **Weg A:** Ein Image nehmen, das fuer Nicht-Root gebaut ist
* **Weg B:** Das Standard-Image `nginx:1.30` behalten und den Pod so anpassen, dass nginx als UID 1000 laufen kann

Versucht es zuerst ohne die Hinweise. Wenn ihr nicht weiterkommt, klappt die
Hinweise nacheinander auf.

<details>
<summary>Hinweis 1: Wo schaue ich zuerst?</summary>

`kubectl describe pod` zeigt euch, **dass** der Container mit `Exit Code: 1`
beendet wurde und der Kubelet ihn mit `Back-off restarting failed container`
immer wieder neu startet. Es zeigt euch aber **nicht, warum**.

```
kubectl describe pod -n debug-<dein-name> -l app=nginx-nonroot | grep -A5 "Last State"
```

```
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
```

Der Grund steht in den Logs des Containers - `kubectl logs` funktioniert auch
bei einem abgestuerzten Container, weil der Kubelet die Ausgabe des letzten
Laufs aufhebt.

</details>

<details>
<summary>Hinweis 2: Was sagen die Logs?</summary>

```
kubectl logs -n debug-<dein-name> deploy/nginx-nonroot
```

```
10-listen-on-ipv6-by-default.sh: info: can not modify /etc/nginx/conf.d/default.conf (read-only file system?)
...
2026/09/25 09:28:44 [warn] 1#1: the "user" directive makes sense only if the master process runs with super-user privileges, ignored in /etc/nginx/nginx.conf:2
2026/09/25 09:28:44 [emerg] 1#1: mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)
nginx: [emerg] mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)
```

Die Zeile mit `[emerg]` ist entscheidend: nginx will beim Start Unterverzeichnisse
in `/var/cache/nginx` anlegen und bekommt `Permission denied`. Das Verzeichnis
gehoert root, der Prozess laeuft aber als UID 1000.

Die `[warn]`-Zeile zur `user`-Direktive ist harmlos - nginx ignoriert die
Direktive einfach, wenn es nicht als root laeuft.

</details>

<details>
<summary>Hinweis 3: Der Container crasht sofort - wie komme ich mit exec rein?</summary>

`kubectl exec` braucht einen laufenden Container. Trick: Startet das gleiche
Image mit dem gleichen `securityContext`, aber mit `sleep` statt nginx. Dann
koennt ihr in Ruhe nachschauen, wem die Verzeichnisse gehoeren.

```
nano 99-inspect.yml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-inspect
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 1000
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:1.30
    command: ["sleep", "3600"]
```

```
kubectl apply -f 99-inspect.yml -n debug-<dein-name>
kubectl exec -n debug-<dein-name> nginx-inspect -- id
kubectl exec -n debug-<dein-name> nginx-inspect -- ls -ld /var/cache/nginx /var/run /run /etc/nginx/conf.d
kubectl exec -n debug-<dein-name> nginx-inspect -- grep -n -E "^pid|^ *listen" /etc/nginx/nginx.conf /etc/nginx/conf.d/default.conf
```

```
uid=1000 gid=1000 groups=1000
drwxr-xr-x 2 root root 4096 Sep 19 00:20 /etc/nginx/conf.d
drwxr-xr-x 1 root root 4096 Sep 25 10:08 /run
drwxr-xr-x 2 root root 4096 Sep 15 14:07 /var/cache/nginx
lrwxrwxrwx 1 root root    4 Sep 18 00:00 /var/run -> /run
/etc/nginx/nginx.conf:6:pid        /run/nginx.pid;
/etc/nginx/conf.d/default.conf:2:    listen       80;
```

Daraus koennt ihr ablesen, was nginx als UID 1000 alles **nicht** darf:

| nginx will ... | Verzeichnis | Rechte |
|----------------|-------------|--------|
| Cache-Verzeichnisse anlegen | `/var/cache/nginx` | root, 755 |
| PID-Datei schreiben (`/run/nginx.pid`) | `/run` (= `/var/run`) | root, 755 |
| Port 80 binden | - | privilegierter Port (siehe Hinweis 4) |

Loescht den Inspect-Pod danach wieder:

```
kubectl delete pod nginx-inspect -n debug-<dein-name>
```

</details>

<details>
<summary>Hinweis 4: Ich habe /var/cache/nginx repariert - jetzt kommt der naechste Fehler</summary>

Das ist normal bei dieser Art von Problem: nginx bricht beim **ersten** Fehler
ab. Erst wenn der behoben ist, seht ihr den naechsten. Schaelt die Zwiebel
Schicht fuer Schicht - nach jedem Fix wieder `kubectl logs`.

Reihenfolge, die ihr sehen werdet:

1. `mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)`
2. `open() "/run/nginx.pid" failed (13: Permission denied)`
3. Je nach Cluster: `bind() to 0.0.0.0:80 failed (13: Permission denied)`

Zu Punkt 3: Klassisch darf ein Nicht-Root-Prozess keine Ports unter 1024
binden. Neuere Container-Runtimes (containerd ab 2.0) setzen im Pod aber
`net.ipv4.ip_unprivileged_port_start=0`, dann klappt Port 80 auch als UID 1000.
Ob das bei euch der Fall ist, seht ihr so:

```
kubectl exec -n debug-<dein-name> nginx-inspect -- cat /proc/sys/net/ipv4/ip_unprivileged_port_start
```

`0` heisst: Port 80 ist kein Problem. `1024` heisst: nginx muss auf einen
hoeheren Port (z.B. 8080) umziehen. Auf unserem DOKS-Trainings-Cluster
(containerd 1.7, Stand 09/2026) steht dort `1024` - Punkt 3 tritt bei euch
also auf:

```
2026/09/25 10:13:13 [emerg] 1#1: bind() to 0.0.0.0:80 failed (13: Permission denied)
```
 Verlasst euch nicht darauf - eine saubere
Loesung nutzt einen Port ab 1024, damit sie auf jedem Cluster laeuft.

</details>

<details>
<summary>Loesung Weg A: Image nginxinc/nginx-unprivileged</summary>

Das Image `nginxinc/nginx-unprivileged` ist die offizielle Variante von nginx
fuer Nicht-Root: Es lauscht auf **Port 8080**, die Cache-, PID- und Log-Pfade
liegen in Verzeichnissen, die UID 101 gehoeren, und es laeuft standardmaessig
als Nicht-Root-User. Mit `runAsUser: 1000` funktioniert es trotzdem, weil die
Verzeichnisse fuer alle schreibbar sind.

Zwei Aenderungen im Deployment (Image und Port) und eine im Service (targetPort):

```
nano 01-deployment.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-nonroot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-nonroot
  template:
    metadata:
      labels:
        app: nginx-nonroot
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        runAsNonRoot: true
      containers:
      - name: nginx
        image: nginxinc/nginx-unprivileged:1.30
        ports:
        - containerPort: 8080
```

```
nano 02-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-nonroot
spec:
  selector:
    app: nginx-nonroot
  ports:
  - port: 80
    targetPort: 8080
```

```
kubectl apply -f . -n debug-<dein-name>
kubectl get pods -n debug-<dein-name>
```

</details>

<details>
<summary>Loesung Weg B: Standard-Image nginx:1.30 behalten</summary>

Drei Dinge muessen passieren:

1. `/var/cache/nginx` beschreibbar machen: `emptyDir`-Volume darueber mounten
2. `/var/run` beschreibbar machen (fuer `nginx.pid`): `emptyDir`-Volume darueber mounten
3. nginx auf Port 8080 lauschen lassen: eigene `default.conf` per ConfigMap einhaengen

Ein `emptyDir` wird vom Kubelet mit Rechten `777` angelegt - deshalb darf UID
1000 dort schreiben. Der Inhalt des Image-Verzeichnisses wird dabei
ueberdeckt, was bei `/var/cache/nginx` und `/var/run` egal ist (beide sind im
Image leer).

```
nano 00-configmap.yml
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-default-conf
data:
  default.conf: |
    server {
        listen       8080;
        server_name  localhost;
        location / {
            root   /usr/share/nginx/html;
            index  index.html;
        }
    }
```

```
nano 01-deployment.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-nonroot
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nginx-nonroot
  template:
    metadata:
      labels:
        app: nginx-nonroot
    spec:
      securityContext:
        runAsUser: 1000
        runAsGroup: 1000
        runAsNonRoot: true
      containers:
      - name: nginx
        image: nginx:1.30
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: cache
          mountPath: /var/cache/nginx
        - name: run
          mountPath: /var/run
        - name: default-conf
          mountPath: /etc/nginx/conf.d/default.conf
          subPath: default.conf
      volumes:
      - name: cache
        emptyDir: {}
      - name: run
        emptyDir: {}
      - name: default-conf
        configMap:
          name: nginx-default-conf
```

```
nano 02-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-nonroot
spec:
  selector:
    app: nginx-nonroot
  ports:
  - port: 80
    targetPort: 8080
```

```
kubectl apply -f . -n debug-<dein-name>
kubectl get pods -n debug-<dein-name>
```

Kontrolle mit `exec` - jetzt gehoeren die Verzeichnisse zwar immer noch root,
sind aber fuer alle beschreibbar, und die PID-Datei liegt da:

```
kubectl exec -n debug-<dein-name> deploy/nginx-nonroot -- sh -c 'id; ls -ld /var/cache/nginx /run; ls /run'
```

```
uid=1000 gid=1000 groups=1000
drwxrwxrwx 3 root root 4096 Sep 25 09:32 /run
drwxrwxrwx 7 root root 4096 Sep 25 09:32 /var/cache/nginx
nginx.pid
secrets
```

</details>

## Schritt 5: Loesung pruefen

Egal welcher Weg - so muss es am Ende aussehen:

```
kubectl get pods -n debug-<dein-name>
kubectl logs -n debug-<dein-name> deploy/nginx-nonroot | tail -3
kubectl get endpoints nginx-nonroot -n debug-<dein-name>
```

**Erwartete Ausgabe:**

```
NAME                             READY   STATUS    RESTARTS   AGE
nginx-nonroot-79fb6d876c-vq5bc   1/1     Running   0          30s

2026/09/25 09:32:19 [notice] 1#1: start worker processes
2026/09/25 09:32:19 [notice] 1#1: start worker process 22
2026/09/25 09:32:19 [notice] 1#1: start worker process 23

NAME            ENDPOINTS           AGE
nginx-nonroot   10.244.0.125:8080   5m
```

Und der Test gegen den Service aus einem Wegwerf-Pod heraus:

```
kubectl run curl-test --rm -i --restart=Never -n debug-<dein-name> \
  --image=curlimages/curl:8.10.1 -- curl -s http://nginx-nonroot
```

**Erwartete Ausgabe:** die nginx-Startseite mit `<h1>Welcome to nginx!</h1>`.

## Aufraeumen

```
kubectl delete namespace debug-<dein-name>
```

## Zusammenfassung

| Was ihr gesehen habt | Werkzeug | Erkenntnis |
|----------------------|----------|------------|
| `CrashLoopBackOff`, `Exit Code: 1` | `kubectl get pods`, `kubectl describe pod` | Container startet und stirbt sofort - der Grund steht hier noch nicht |
| `[emerg] mkdir() "/var/cache/nginx/client_temp" failed (13: Permission denied)` | `kubectl logs` | nginx darf als UID 1000 nicht in root-Verzeichnisse schreiben |
| `[emerg] open() "/run/nginx.pid" failed (13: Permission denied)` | `kubectl logs` (nach dem ersten Fix) | Zweite Schicht: PID-Datei |
| Verzeichnisse gehoeren root mit 755 | `kubectl exec` (Inspect-Pod mit `sleep`) | Ursache bestaetigt |

| Loesung | Aufwand | Wann sinnvoll |
|---------|---------|---------------|
| Weg A: `nginxinc/nginx-unprivileged`, Port 8080 | 3 Zeilen | Immer, wenn es ein fertiges Nicht-Root-Image gibt |
| Weg B: `emptyDir` fuer `/var/cache/nginx` und `/var/run` + ConfigMap mit `listen 8080` | ConfigMap + Volumes | Wenn das Image nicht getauscht werden darf oder es kein Nicht-Root-Image gibt |

**Merkhilfe:** `describe` sagt **dass** es crasht, `logs` sagt **warum**, `exec`
(notfalls mit `sleep` statt dem echten Prozess) zeigt euch den **Zustand im Container**.
