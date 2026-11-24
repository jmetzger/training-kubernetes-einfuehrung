# Debugging: Ephemeral Container startet, kann aber nicht alles (Kyverno, UID)

## Hintergrund

Viele Anwendungen laufen auf schlanken Images (distroless, scratch). Dort gibt es
keine Shell, kein `curl`, kein `dig`:

```
kubectl exec <pod> -- sh
# -> executable file not found in $PATH
```

Mit einem **Ephemeral Container** haengt man zur Laufzeit einen zusaetzlichen
Debug-Container in einen **laufenden** Pod, ohne ihn neu zu starten oder neu
zu deployen. Der Debug-Container teilt sich das Netzwerk mit dem Pod
(`localhost` funktioniert) und sieht mit `--target` auch die Prozesse der App.

![Ephemeral Container und Kyverno](img/25-ephemeral-debug-kyverno.svg)

### Die Situation in dieser Uebung

- Eine Kyverno-Policy erzwingt `runAsNonRoot: true`, auch fuer Debug-Container.
- Das Debug-Image hat einen **numerischen** `USER` (hier 999), damit es die Policy besteht.
- Die Anwendung laeuft mit einer **anderen UID** (hier 10001).

Ergebnis: Der Debug-Container **startet**, aber einiges geht nicht.

| Aktion | Mit UID 999 (andere UID als die App) | Loesung |
|--------|--------------------------------------|---------|
| `ps`, `curl localhost`, `dig`, `ss` | geht | - |
| `cat /proc/1/environ` | `Permission denied` | Debug-Container mit **UID der App** starten |
| `ls /proc/1/root/` (Dateien der App) | `Permission denied` | Debug-Container mit **UID der App** starten |
| `kubectl debug --copy-to` | von Kyverno abgelehnt | `--profile=restricted --custom=...` |

## Voraussetzung (Trainer)

Kyverno muss im Cluster installiert sein. Falls nicht, als Trainer einmalig:

```
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --version 3.7.2 -n kyverno --create-namespace \
  --set global.image.registry=ghcr.io
kubectl get pods -n kyverno
```

`global.image.registry=ghcr.io` holt die Images von GitHub statt von `reg.kyverno.io`
(die Registry war beim Test zeitweise nicht erreichbar, 502/503).

Hinweis: Ab Kyverno 1.20 werden `kyverno.io/v1` `Policy` und `ClusterPolicy` nicht
mehr angenommen. Diese Uebung nutzt deshalb Kyverno 1.17 (Chart 3.7.2).

Alle Pods in `kyverno` muessen `Running` sein.

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 25-debug-ephemeral-container-kyverno
cd 25-debug-ephemeral-container-kyverno
```

```
kubectl create namespace kyverno-debug-<dein-name>
```

## Schritt 2: Kyverno-Policy anlegen

Die Policy gilt nur in eurem Namespace (`Policy`, nicht `ClusterPolicy`).

```
# vi 01-policy.yml
apiVersion: kyverno.io/v1
kind: Policy
metadata:
  name: require-run-as-nonroot
spec:
  validationFailureAction: Enforce
  background: false
  rules:
    - name: run-as-non-root
      match:
        any:
          - resources:
              kinds:
                - Pod
                - Pod/ephemeralcontainers
      validate:
        message: "Alle Container (auch Ephemeral Container) muessen runAsNonRoot: true setzen."
        pattern:
          spec:
            containers:
              - securityContext:
                  runAsNonRoot: true
            =(ephemeralContainers):
              - securityContext:
                  runAsNonRoot: true
```

Wichtig ist `Pod/ephemeralcontainers` unter `kinds`. Ohne diese Zeile greift die Policy
nicht beim Anhaengen eines Debug-Containers.

```
kubectl apply -f 01-policy.yml -n kyverno-debug-<dein-name>
kubectl get policy -n kyverno-debug-<dein-name>
```

Es sollte `READY: True` angezeigt werden.

Beim `apply` erscheint evtl. eine Warnung, dass der `kyverno-reports-controller` keine
Rechte auf `Pod/ephemeralcontainers` hat. Sie ist fuer die Uebung harmlos.

## Schritt 3: Anwendung ohne Shell deployen

Die App ist ein statisches Go-Binary (`FROM scratch`): keine Shell, keine Tools.
Sie laeuft mit der **UID 10001**. Das Passwort ist nur ein Uebungswert.

```
# vi 02-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
        - name: app
          image: hashicorp/http-echo:1.0
          args:
            - "-text=hallo aus dem Pod"
          ports:
            - containerPort: 5678
          env:
            - name: DB_PASSWORD
              value: geheim123
          securityContext:
            runAsNonRoot: true
            runAsUser: 10001
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
            seccompProfile:
              type: RuntimeDefault
```

```
kubectl apply -f 02-deployment.yml -n kyverno-debug-<dein-name>
kubectl rollout status deploy/app -n kyverno-debug-<dein-name>
kubectl get pods -n kyverno-debug-<dein-name>
```

Eine Shell gibt es nicht:

```
POD=$(kubectl get pod -n kyverno-debug-<dein-name> -l app=app -o jsonpath='{.items[0].metadata.name}')
kubectl exec -n kyverno-debug-<dein-name> $POD -- sh
```

**Erwarteter Fehler:**
```
exec: "sh": executable file not found in $PATH
```

## Schritt 4: Debug-Container startet, aber mit anderer UID als die App

`nicolaka/netshoot` ist ein Debug-Image mit `curl`, `dig`, `ss`, `ps` und mehr. Es startet
eigentlich als root. Damit es die Policy besteht, wird es hier wie ein Image mit
`USER 999` gestartet. Die UID wird per `--custom` angegeben (kubectl ab 1.31):

```
# vi debug-999.json
{"securityContext": {"runAsUser": 999, "runAsNonRoot": true}}
```

```
kubectl debug -n kyverno-debug-<dein-name> $POD -it --image=nicolaka/netshoot --target=app \
  --profile=restricted --custom=debug-999.json --container=dbg-999 -- sh
```

Der Debug-Container **startet**. Im Debug-Container:

```
id -u
ps -ef
curl localhost:5678
```

**Erwartet:**
- `id -u` zeigt `999`
- `ps -ef` zeigt `/http-echo ...` als PID 1 (wegen `--target=app`)
- `curl` zeigt `hallo aus dem Pod`

Netzwerk und Prozessliste funktionieren also.

## Schritt 5: Was nicht geht - /proc/1

Weiter im Debug-Container:

```
cat /proc/1/environ
ls /proc/1/root/
exit
```

**Erwarteter Fehler:**
```
cat: can't open '/proc/1/environ': Permission denied
ls: /proc/1/root/: Permission denied
```

Das ist **kein Kyverno-Problem**, sondern Linux: `/proc/<pid>/environ` und
`/proc/<pid>/root` darf nur lesen, wer dieselbe UID wie der Prozess hat (oder
`CAP_SYS_PTRACE`). Der Debug-Container laeuft als 999, die App als 10001.

Auch `printenv DB_PASSWORD` im Debug-Container hilft nicht: Der Debug-Container hat
seine eigene Umgebung. Die Variablen der App stehen nur in `/proc/1/environ`.

## Schritt 6: Loesung - Debug-Container mit der UID der App

Erst die UID der App herausfinden (hier ist sie im Manifest bekannt):

```
kubectl get pod $POD -n kyverno-debug-<dein-name> \
  -o jsonpath='{.spec.containers[0].securityContext.runAsUser}{"\n"}'
```

Dann den Debug-Container mit genau dieser UID starten. `runAsNonRoot` bleibt erfuellt:

```
# vi debug.json
{"securityContext": {"runAsUser": 10001, "runAsNonRoot": true}}
```

```
kubectl debug -n kyverno-debug-<dein-name> $POD -it --image=nicolaka/netshoot --target=app \
  --profile=restricted --custom=debug.json --container=dbg-uid -- sh
```

Im Debug-Container:

```
id -u
cat /proc/1/environ | tr "\0" "\n" | grep DB_
ls /proc/1/root/
exit
```

**Erwartet:**
- `id -u` zeigt `10001`
- `/proc/1/environ` ist lesbar, `DB_PASSWORD` taucht auf
- `/proc/1/root/` ist lesbar, darin liegt u.a. die Datei `http-echo` der App

Ohne Aenderung an der Kyverno-Policy: Es ist nur die UID des Debug-Containers angepasst.

## Schritt 7: Was nicht geht - kubectl debug --copy-to

Mit `--copy-to` wird nicht der laufende Pod veraendert, sondern eine Kopie angelegt, in der
der Debug-Container ein normaler Container ist.

```
kubectl debug -n kyverno-debug-<dein-name> $POD --copy-to=app-debug1 \
  --image=nicolaka/netshoot --container=dbgcopy -- sleep 600
```

**Erwarteter Fehler:**
```
resource Pod/kyverno-debug-<dein-name>/app-debug1 was blocked due to the following policies

require-run-as-nonroot:
  run-as-non-root: 'validation error: ... failed at path /spec/containers/1/securityContext/runAsNonRoot/'
```

Das Standardprofil setzt keinen `securityContext`, der Container liefe als root.

## Schritt 8: Loesung - copy-to mit Profil restricted und UID

```
kubectl debug -n kyverno-debug-<dein-name> $POD --copy-to=app-debug2 \
  --profile=restricted --custom=debug.json --share-processes \
  --image=nicolaka/netshoot --container=dbgcopy2 -- sleep 600
```

```
kubectl get pods -n kyverno-debug-<dein-name>
```

**Erwartet:** `app-debug2` mit `2/2 Running`.

## Schritt 9: Weitere Stolpersteine

Zwei Fehler, die beim Debuggen mit Kyverno haeufig auftauchen:

**a) Kein Profil, kein securityContext**

```
kubectl debug -n kyverno-debug-<dein-name> $POD -it --image=nicolaka/netshoot --target=app -- sh
```

Kyverno lehnt ab (`runAsNonRoot` fehlt), gleiche Policy-Meldung wie in Schritt 7. Nur der Pfad
am Ende heisst hier `/spec/ephemeralContainers/<n>/securityContext/runAsNonRoot/`.

**b) Profil restricted, aber das Image startet als root**

```
kubectl debug -n kyverno-debug-<dein-name> $POD -it --image=nicolaka/netshoot --target=app \
  --profile=restricted --container=dbg-restricted -- id
```

Der Befehl haengt (mit Strg+C abbrechen). Der Grund:

```
kubectl get pod $POD -n kyverno-debug-<dein-name> \
  -o jsonpath='{range .status.ephemeralContainerStatuses[*]}{.name}{" -> "}{.state}{"\n"}{end}'
```

```
dbg-restricted -> {"waiting":{"message":"container has runAsNonRoot and image has non-numeric user (root), cannot verify user is non-root ...","reason":"CreateContainerConfigError"}}
```

Kyverno besteht, aber der Kubelet kann bei `runAsNonRoot` nur mit einer **numerischen UID**
pruefen. Eigene Debug-Images deshalb mit numerischem User bauen, z.B. `USER 999` statt
`USER root` oder `USER tekton`.

Ein Ephemeral Container laesst sich nicht mehr entfernen. Er bleibt im Pod, bis der Pod
ersetzt wird.

## Aufraeumen

```
kubectl delete namespace kyverno-debug-<dein-name>
```

Trainer, nach der Uebung: Kyverno wieder entfernen.

```
helm uninstall kyverno -n kyverno
kubectl delete namespace kyverno
```

## Zusammenfassung

| Befehl | Ergebnis | Loesung |
|--------|----------|---------|
| Debug-Container mit UID 999 (App: 10001) | startet, `ps`/`curl` gehen | - |
| `/proc/1/environ`, `/proc/1/root` mit UID 999 | `Permission denied` | UID der App per `--custom` |
| `--copy-to` mit Standardprofil | Von Kyverno abgelehnt | `--profile=restricted --custom=...` |
| `kubectl debug` ohne Profil | Von Kyverno abgelehnt | `--profile=restricted --custom=...` |
| `--profile=restricted`, Image startet als root | `CreateContainerConfigError` | Numerische UID per `--custom` oder `USER` im Image |
