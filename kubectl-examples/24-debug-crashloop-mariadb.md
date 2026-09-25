# Debugging: CrashLoopBackOff bei MariaDB - Konfiguration kommt nicht an

## Hintergrund

`CrashLoopBackOff` ist kein Fehler, sondern ein Zustand: Der Container ist
gestartet, hat sich sofort wieder beendet, und der Kubelet startet ihn mit
immer laengeren Wartezeiten neu (10s, 20s, 40s ... bis 5 Minuten). Warum der
Container stirbt, sagt euch dieser Status nicht - das muesst ihr selbst
herausfinden.

Die haeufigste Ursache in der Praxis ist nicht das Image und nicht der
Cluster, sondern fehlende oder falsche Konfiguration: Eine Umgebungsvariable
fehlt, hat den falschen Namen oder zeigt auf einen Secret-Key, den es nicht gibt.

Dabei gibt es zwei ganz unterschiedliche Fehlerbilder, die ihr auseinanderhalten
muesst:

| Status | Container ist gestartet? | Wo steht der Grund? |
|--------|--------------------------|---------------------|
| `CrashLoopBackOff` | Ja, und wieder gestorben | in `kubectl logs` |
| `CreateContainerConfigError` | Nein, Kubelet konnte ihn nicht einmal bauen | in `kubectl describe` (Events) |

In dieser Uebung lauft ihr in beide.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 24-debug-crashloop-mariadb
cd 24-debug-crashloop-mariadb
```

## Schritt 2: Secret und Deployment anlegen

Das Root-Passwort fuer MariaDB liegt in einem Secret und wird als
Umgebungsvariable in den Container gereicht.

Achtung: Das Deployment funktioniert absichtlich nicht.

```
nano 01-secret.yml
```

```
apiVersion: v1
kind: Secret
metadata:
  name: mariadb-secret
type: Opaque
stringData:
  root-password: training123
```

```
nano 02-mariadb.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mariadb
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb
        image: mariadb:11.4
        ports:
        - containerPort: 3306
        env:
        - name: MARIADB_ROOT_PASSWD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: root-password
```

```
kubectl create ns crash-<dein-name>
kubectl apply -f . -n crash-<dein-name>
```

## Schritt 3: Symptom beobachten

```
kubectl get pods -n crash-<dein-name> -w
```

Beobachtet den Status ein bis zwei Minuten lang, dann mit `Strg+C` abbrechen.

**Erwartete Ausgabe:**

```
NAME                       READY   STATUS             RESTARTS      AGE
mariadb-59c856749d-frgtl   0/1     Error              0             15s
mariadb-59c856749d-frgtl   0/1     Error              1 (5s ago)    20s
mariadb-59c856749d-frgtl   0/1     CrashLoopBackOff   1 (6s ago)    21s
mariadb-59c856749d-frgtl   0/1     Error              2 (17s ago)   35s
mariadb-59c856749d-frgtl   0/1     CrashLoopBackOff   2 (18s ago)   36s
mariadb-59c856749d-frgtl   0/1     Error              3 (63s ago)   89s
```

Der Status pendelt zwischen `Error` und `CrashLoopBackOff`, der Restart-Zaehler
steigt, und der Abstand zwischen den Versuchen wird laenger.

## Schritt 4: Aufgabe - Ursache finden und beheben

Bringt MariaDB nach `Running`. Zum Schluss muss dieser Befehl die Version
ausgeben:

```
kubectl exec -n crash-<dein-name> deploy/mariadb -- \
  sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "SELECT VERSION();"'
```

Eure Werkzeuge:

```
kubectl describe pod -n crash-<dein-name> -l app=mariadb
kubectl logs -n crash-<dein-name> deploy/mariadb
kubectl logs -n crash-<dein-name> deploy/mariadb --previous
```

<details>
<summary>Hinweis 1: Was sagt describe?</summary>

```
kubectl describe pod -n crash-<dein-name> -l app=mariadb
```

Interessant sind drei Stellen: der Zustand des Containers, seine
Umgebungsvariablen und die Events.

```
    State:          Terminated
      Reason:       Error
      Exit Code:    1
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
    Restart Count:  3
    Environment:
      MARIADB_ROOT_PASSWD:  <set to the key 'root-password' in secret 'mariadb-secret'>  Optional: false
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Pulled     81s                kubelet            Successfully pulled image "mariadb:11.4"
  Normal   Created    35s (x4 over 81s)  kubelet            Container created
  Normal   Started    35s (x4 over 81s)  kubelet            Container started
  Warning  BackOff    33s (x3 over 77s)  kubelet            Back-off restarting failed container mariadb in pod ...
```

Wichtig: `Container created`, `Container started` - Kubernetes hat seinen Job
erledigt. Das Image ist da, die Umgebungsvariable ist gesetzt, der Container
lief. Er hat sich nur mit `Exit Code: 1` selbst beendet. Warum, steht hier
nicht. Das weiss nur der Prozess selbst - also: Logs.

</details>

<details>
<summary>Hinweis 2: Was sagen die Logs?</summary>

```
kubectl logs -n crash-<dein-name> deploy/mariadb
```

```
2026-09-25 09:45:16+00:00 [Note] [Entrypoint]: Entrypoint script for MariaDB Server 1:11.4.13+maria~ubu2404 started.
2026-09-25 09:45:16+00:00 [Note] [Entrypoint]: Switching to dedicated user 'mysql'
2026-09-25 09:45:16+00:00 [ERROR] [Entrypoint]: Database is uninitialized and password option is not specified
	You need to specify one of MARIADB_ROOT_PASSWORD, MARIADB_ROOT_PASSWORD_HASH, MARIADB_ALLOW_EMPTY_ROOT_PASSWORD and MARIADB_RANDOM_ROOT_PASSWORD
```

MariaDB sagt euch sogar, welche Variablen es akzeptiert. Vergleicht die Liste
mit dem, was in `describe` unter `Environment:` steht.

Falls der Container gerade neu gestartet wurde und die Logs leer sind, holt
euch die Logs des vorherigen Laufs:

```
kubectl logs -n crash-<dein-name> deploy/mariadb --previous
```

</details>

<details>
<summary>Loesung</summary>

Die Umgebungsvariable heisst `MARIADB_ROOT_PASSWD` - MariaDB erwartet
`MARIADB_ROOT_PASSWORD`. Der Secret-Key und das Secret selbst sind in Ordnung,
nur der Name der Variable ist falsch.

```
nano 02-mariadb.yml
```

```
        env:
        - name: MARIADB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: root-password
```

```
kubectl apply -f . -n crash-<dein-name>
kubectl get pods -n crash-<dein-name>
```

Das Deployment rollt einen neuen Pod aus, der alte wird beendet.

```
NAME                       READY   STATUS        RESTARTS   AGE
mariadb-59c856749d-frgtl   0/1     Terminating   4          3m
mariadb-77d9677ddf-vdrr5   1/1     Running       0          2s
```

</details>

## Schritt 5: Loesung pruefen

```
kubectl logs -n crash-<dein-name> deploy/mariadb | tail -2
```

```
2026-09-25  9:46:21 0 [Note] mariadbd: ready for connections.
Version: '11.4.13-MariaDB-ubu2404'  socket: '/run/mysqld/mysqld.sock'  port: 3306  mariadb.org binary distribution
```

```
kubectl exec -n crash-<dein-name> deploy/mariadb -- \
  sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -e "SELECT VERSION();"'
```

```
VERSION()
11.4.13-MariaDB-ubu2404
```

## Schritt 6: Zum Vergleich - der Fehler, der NICHT in den Logs steht

Jetzt baut ihr absichtlich einen zweiten Fehler ein: Der Name der Variable
bleibt richtig, aber der Secret-Key im Manifest bekommt einen Tippfehler.

```
nano 02-mariadb.yml
```

```
        env:
        - name: MARIADB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mariadb-secret
              key: rootpassword
```

```
kubectl apply -f . -n crash-<dein-name>
kubectl get pods -n crash-<dein-name>
```

**Erwartete Ausgabe:**

```
NAME                       READY   STATUS                       RESTARTS   AGE
mariadb-756d99d6c-xhqhp    0/1     CreateContainerConfigError   0          20s
mariadb-77d9677ddf-vdrr5   1/1     Running                      0          2m
```

Der neue Pod kommt gar nicht erst in `CrashLoopBackOff`: `RESTARTS` bleibt
bei `0`. Und der alte Pod laeuft weiter, weil das Deployment einen Pod, der
nicht `Ready` wird, nicht gegen den funktionierenden austauscht.

Die Logs helfen diesmal nicht:

```
kubectl logs -n crash-<dein-name> -l app=mariadb --prefix | grep 756d99d6c
```

Fuer den neuen Pod bekommt ihr keine Ausgabe. Direkt gefragt:

```
kubectl logs -n crash-<dein-name> mariadb-756d99d6c-xhqhp
```

```
Error from server (BadRequest): container "mariadb" in pod "mariadb-756d99d6c-xhqhp" is waiting to start: CreateContainerConfigError
```

Es gibt keine Logs, weil der Container nie gestartet ist. Diesmal steht der
Grund in den Events:

```
kubectl describe pod -n crash-<dein-name> mariadb-756d99d6c-xhqhp | grep -A8 "^Events:"
```

```
  Warning  Failed     12s (x3 over 26s)  kubelet            Error: couldn't find key rootpassword in Secret crash-<dein-name>/mariadb-secret
```

Key wieder auf `root-password` aendern und erneut anwenden:

```
kubectl apply -f . -n crash-<dein-name>
kubectl get pods -n crash-<dein-name>
```

## Aufraeumen

```
kubectl delete namespace crash-<dein-name>
```

## Zusammenfassung

| Status | `RESTARTS` | `kubectl logs` | `kubectl describe` Events | Typische Ursache |
|--------|------------|----------------|---------------------------|------------------|
| `CrashLoopBackOff` | steigt | zeigt den Grund (`[ERROR] ... password option is not specified`) | nur `Back-off restarting failed container` | Anwendung bekommt falsche/fehlende Konfiguration |
| `CreateContainerConfigError` | bleibt 0 | `is waiting to start` - keine Logs | zeigt den Grund (`couldn't find key ... in Secret`) | Manifest zeigt auf ConfigMap/Secret/Key, den es nicht gibt |

**Merkhilfe:** `RESTARTS` steigt - der Container lief, frag die Logs.
`RESTARTS` bleibt 0 und der Status ist nicht `Running` - Kubernetes hat ihn
gar nicht erst gebaut, frag `describe`.
