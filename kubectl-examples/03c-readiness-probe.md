# Uebung: Readiness Probe mit HTTP

## Hintergrund

Die Readiness Probe entscheidet, ob ein Pod **Traffic empfangen darf**.  
Solange die Probe fehlschlaegt, entfernt Kubernetes den Pod aus den Service-Endpoints.

| Probe | Was passiert bei Fehler? | Pod wird neu gestartet? |
|-------|--------------------------|------------------------|
| Readiness | Pod bekommt keinen Traffic | Nein |
| Liveness | Pod wird neu gestartet | Ja |

In dieser Uebung prueft die Readiness Probe per HTTP ob die Datei `/ready`  
im nginx-Webroot existiert. Ist sie nicht da → 404 → Pod NotReady → kein Traffic.

---

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests
cd manifests
mkdir 03c-readiness-probe
cd 03c-readiness-probe
```

---

## Schritt 2: Deployment erstellen

```
nano 01-deploy.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-readiness
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-readiness
  template:
    metadata:
      labels:
        app: nginx-readiness
    spec:
      securityContext:
        fsGroup: 101
      containers:
      - name: nginx
        image: nginxinc/nginx-unprivileged:1.28
        ports:
        - containerPort: 8080
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          failureThreshold: 2
        volumeMounts:
        - name: webroot
          mountPath: /usr/share/nginx/html
      volumes:
      - name: webroot
        emptyDir: {}
```

---

## Schritt 3: Service erstellen

```
nano 02-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: nginx-readiness-svc
spec:
  selector:
    app: nginx-readiness
  ports:
  - port: 80
    targetPort: 8080
```

---

## Schritt 4: Deployen

```
kubectl create namespace readiness-<dein-name>
kubectl apply -f . -n readiness-<dein-name>
```

---

## Schritt 5: Pods beobachten — alle sind 0/1

```
kubectl get pods -n readiness-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                              READY   STATUS    RESTARTS   AGE
nginx-readiness-95cc7554d-4kvsg   0/1     Running   0          12s
nginx-readiness-95cc7554d-89zr7   0/1     Running   0          12s
nginx-readiness-95cc7554d-8mrf7   0/1     Running   0          12s
```

Die Pods laufen, aber sind **nicht ready** — die HTTP-Probe bekommt noch 404.

---

## Schritt 6: Probe-Fehler ansehen

```
kubectl describe pod -l app=nginx-readiness -n readiness-<dein-name>
```

In den Events steht:
```
Warning  Unhealthy  kubelet  Readiness probe failed: HTTP probe failed with statuscode: 404
```

Und in den Conditions:
```
Ready             False
ContainersReady   False
```

---

## Schritt 7: Service hat keine Endpoints

```
kubectl get endpoints nginx-readiness-svc -n readiness-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                  ENDPOINTS   AGE
nginx-readiness-svc               30s
```

Kein Pod bekommt Traffic — das ist das Wirkprinzip der Readiness Probe.

---

## Schritt 8: Einen Pod "bereit machen"

Einen Pod-Namen merken:
```
kubectl get pods -n readiness-<dein-name>
```

Die Datei `/ready` im Webroot anlegen — nginx antwortet jetzt mit 200:
```
kubectl exec -n readiness-<dein-name> <pod-name> -- sh -c 'echo ok > /usr/share/nginx/html/ready'
```

Nach ~10 Sekunden prueft die Probe erneut:
```
kubectl get pods -n readiness-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                              READY   STATUS    RESTARTS   AGE
nginx-readiness-95cc7554d-4kvsg   1/1     Running   0          45s
nginx-readiness-95cc7554d-89zr7   0/1     Running   0          45s
nginx-readiness-95cc7554d-8mrf7   0/1     Running   0          45s
```

Und der Service hat jetzt genau einen Endpoint:
```
kubectl get endpoints nginx-readiness-svc -n readiness-<dein-name>
```

```
NAME                  ENDPOINTS           AGE
nginx-readiness-svc   10.108.0.240:8080   46s
```

---

## Schritt 9: Alle Pods ready machen

Fuer die anderen zwei Pods ebenfalls die Datei anlegen:
```
kubectl exec -n readiness-<dein-name> <pod-name-2> -- sh -c 'echo ok > /usr/share/nginx/html/ready'
kubectl exec -n readiness-<dein-name> <pod-name-3> -- sh -c 'echo ok > /usr/share/nginx/html/ready'
```

```
kubectl get pods -n readiness-<dein-name>
kubectl get endpoints nginx-readiness-svc -n readiness-<dein-name>
```

**Erwartete Ausgabe:**
```
NAME                              READY   STATUS    RESTARTS   AGE
nginx-readiness-95cc7554d-4kvsg   1/1     Running   0          70s
nginx-readiness-95cc7554d-89zr7   1/1     Running   0          70s
nginx-readiness-95cc7554d-8mrf7   1/1     Running   0          70s

NAME                  ENDPOINTS                                             AGE
nginx-readiness-svc   10.108.0.22:8080,10.108.0.240:8080,10.108.1.48:8080   71s
```

Alle 3 Pods sind ready — alle 3 sind im Service.

---

## Schritt 10: Pod waehrend Betrieb "krank machen"

Datei aus einem laufenden Pod entfernen:
```
kubectl exec -n readiness-<dein-name> <pod-name> -- rm /usr/share/nginx/html/ready
```

Nach ~10 Sekunden:
```
kubectl get pods -n readiness-<dein-name>
kubectl get endpoints nginx-readiness-svc -n readiness-<dein-name>
```

**Was passiert:**
```
NAME                              READY   STATUS    RESTARTS   AGE
nginx-readiness-95cc7554d-4kvsg   0/1     Running   0          90s   <- NotReady
nginx-readiness-95cc7554d-89zr7   1/1     Running   0          90s
nginx-readiness-95cc7554d-8mrf7   1/1     Running   0          90s

NAME                  ENDPOINTS                           AGE
nginx-readiness-svc   10.108.0.22:8080,10.108.1.48:8080   91s
```

**Wichtig:** `RESTARTS: 0` — der Pod wird **nicht neu gestartet**.  
Er bekommt nur keinen Traffic mehr, laeuft aber weiter.

---

## Aufraeumen

```
kubectl delete namespace readiness-<dein-name>
```

---

## Zusammenfassung

| Was passiert | Ergebnis |
|-------------|---------|
| Probe schlaegt fehl (404) | Pod = NotReady, kein Endpoint im Service |
| Probe erfolgreich (200) | Pod = Ready, Endpoint im Service |
| Probe schlaegt wieder fehl | Pod aus Endpoints entfernt, **kein Neustart** |
| Service | Routet Traffic nur zu Ready-Pods |

Die Readiness Probe schuetzt andere Pods und Nutzer davor, Anfragen an einen  
Pod zu senden, der noch nicht (oder nicht mehr) bereit ist sie zu verarbeiten.
