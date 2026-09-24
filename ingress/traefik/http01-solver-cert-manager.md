# cert-manager HTTP-01 Solver: Wo landet die well-known-Datei?

Frage aus dem Training: Beim `http-01`-Check erstellt cert-manager kurz ein eigenes
Ingress-Objekt (siehe Screenshot in
[https-letsencrypt-ingress-traefik.md](/ingress/https-letsencrypt-ingress-traefik.md)). Wo genau
liegt die Datei unter `/.well-known/acme-challenge/<token>`, und wie kommt der Traffic über
Traefik dahin?

**Hinweis:** Diese Übung ist noch nicht live auf einem Cluster verifiziert (siehe TEST-PFLICHT im
Skill `workshop-training`). Bevor sie im Training als "fertig getestet" verwendet wird, einmal mit
einem laufenden Trainings-Cluster (Traefik + cert-manager + echte Subdomain unter `do.t3isp.de`)
durchgehen und Step 3/4 mit echtem Output ergänzen.

## Vorwissen (Kurzfassung)

Es gibt **keine Datei auf einem Volume**. cert-manager baut für die Dauer der Challenge (meist nur
wenige Sekunden) drei temporäre Objekte im **Namespace des Certificates**:

1. Einen **Solver-Pod** (`quay.io/jetstack/cert-manager-acmesolver`) - ein kleiner Go-HTTP-Server,
   der auf Port `8089` genau eine Route beantwortet: `GET /.well-known/acme-challenge/<token>`.
   Die Antwort (Token + Fingerprint des ACME-Account-Keys) wird zur Laufzeit aus den
   Challenge-Parametern berechnet, nicht aus einer Datei gelesen.
2. Einen **Service** (ClusterIP), der auf diesen Pod zeigt.
3. Ein **Ingress** (Name `cm-acme-http-solver-<hash>`) mit genau einer Pfad-Regel auf
   `/.well-known/acme-challenge/<token>` -> Service.

Traefik sieht dieses Ingress ganz normal über seinen Watch auf die Ingress-API und baut daraus
einen Router mit dem Matcher `PathPrefix(...)` - denselben Mechanismus, den wir in
[pathtype-implementationspecific.md](pathtype-implementationspecific.md) schon für
`Prefix`/`ImplementationSpecific` angeschaut haben.

Das prüfen wir jetzt live nach - Voraussetzung ist die abgeschlossene Übung
[https-letsencrypt-ingress-traefik.md](/ingress/https-letsencrypt-ingress-traefik.md) (cert-manager
+ ClusterIssuer laufen bereits, ein Ingress mit
`cert-manager.io/cluster-issuer: "letsencrypt-prod"` existiert).

## Step 1: Vorbereitung - Watch-Fenster aufmachen

Der Solver läuft nur für den Zeitraum der Challenge (Sekunden bis wenige Minuten). Damit man ihn
überhaupt sieht, muss man **parallel zum Auslösen** der Challenge schon einen Watch laufen haben.

```
cd
mkdir -p manifests/http01-solver-watch
cd manifests/http01-solver-watch
```

In einem eigenen Terminal (oder `tmux`-Split) parallel laufen lassen, im Namespace, in dem euer
`Certificate`/`Ingress` mit dem `cert-manager.io/cluster-issuer`-Annotation liegt:

```
kubectl get pod,svc,ingress -w
```

In einem zweiten Terminal parallel:

```
kubectl get challenges -w
```

## Step 2: Challenge auslösen

Am einfachsten: Ein neues `Certificate` (oder ein Ingress mit `cert-manager.io/cluster-issuer`)
anlegen, für das noch kein gültiges Secret existiert - z.B. mit einer neuen Subdomain aus der
vorherigen Übung:

```
nano ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: solver-test-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - solvertest-<dein-name>.appv2.do.t3isp.de
    secretName: solver-test-tls
  rules:
  - host: "solvertest-<dein-name>.appv2.do.t3isp.de"
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service:
              name: apple-service
              port:
                number: 80
```

```
kubectl apply -f ingress.yml
```

## Step 3: Beobachten, was cert-manager anlegt

Im Watch-Fenster aus Step 1 sollte kurz aufblitzen (Reihenfolge: Pod -> Service -> Ingress):

```
NAME                                    READY   STATUS    RESTARTS   AGE
pod/cm-acme-http-solver-xxxxx           1/1     Running   0          3s

NAME                                    TYPE        CLUSTER-IP     PORT(S)
service/cm-acme-http-solver-xxxxx       ClusterIP   10.x.x.x       8089/TCP

NAME                                              CLASS     HOSTS
ingress.networking.k8s.io/cm-acme-http-solver-xxxxx   traefik   solvertest-<dein-name>.appv2.do.t3isp.de
```

Solange die Objekte existieren, direkt reinschauen:

```
kubectl get ingress cm-acme-http-solver-xxxxx -o yaml
```

Wichtig zu sehen: `spec.rules[0].http.paths[0].path` ist exakt
`/.well-known/acme-challenge/<token>` - derselbe Token wie in

```
kubectl get challenges -o yaml
```

unter `spec.token` / `spec.key`.

Von außen (falls schnell genug) lässt sich der Pfad sogar direkt abrufen:

```
curl http://solvertest-<dein-name>.appv2.do.t3isp.de/.well-known/acme-challenge/<token-aus-challenge>
```

Antwort ist der `key`-Wert aus der Challenge (Token + Fingerprint des Account-Keys), **nicht**
Inhalt einer Datei.

## Step 4: Aufräumen durch cert-manager selbst beobachten

Nach erfolgreicher Validierung (Status der Challenge wechselt auf `valid`) räumt cert-manager Pod,
Service und Ingress automatisch wieder ab - kein manuelles Löschen nötig:

```
kubectl get challenges
kubectl get pod,svc,ingress
# cm-acme-http-solver-* sollte nach kurzer Zeit weg sein
kubectl get certificate solver-test-tls
# READY: True
```

## Aufräumen (eigene Testobjekte)

```
kubectl delete ingress solver-test-ingress
kubectl delete secret solver-test-tls
```

## Zusammenfassung

| Frage | Antwort |
|-------|---------|
| Wo liegt `/.well-known/acme-challenge/<token>` physisch? | Nirgends als Datei - wird vom Solver-Pod zur Laufzeit aus Token+Key berechnet und per HTTP-Handler ausgeliefert. |
| In welchem Namespace laufen Solver-Pod/Service/Ingress? | Im selben Namespace wie das `Certificate`, nicht im `cert-manager`-Namespace. |
| Wer routet den Traffic dahin? | Ein von cert-manager temporär erzeugtes Ingress-Objekt, das Traefik ganz normal über seinen Ingress-Watch aufnimmt und als `PathPrefix`-Router einrichtet. |
| Wie lange existieren die Objekte? | Nur für die Dauer der Challenge (typ. Sekunden bis wenige Minuten), danach automatisches Cleanup. |
| Kann cert-manager statt eines neuen Ingress ein bestehendes patchen? | Ja, über `solvers[].http01.ingress.name` im Issuer/ClusterIssuer statt eines neu erzeugten Ingress. |

## Wichtige Fallstricke

* Der `http-01`-Check läuft immer über Port 80/HTTP, unabhängig davon, dass am Ende ein
  HTTPS-Zertifikat rauskommt - Traefik-EntryPoint für Port 80 muss von außen erreichbar sein.
* DNS muss extern auflösen, da Let's Encrypt von außen validiert.
* Das Zeitfenster zum Beobachten ist kurz - ohne laufenden `-w`-Watch verpasst man die Objekte
  meistens.

## Referenzen

* [cert-manager Doku: HTTP-01 Challenges](https://cert-manager.io/docs/configuration/acme/http01/)
* [cert-manager Doku: ACME Issuer](https://cert-manager.io/docs/configuration/acme/)
* Quellcode acmesolver: [`cmd/acmesolver`](https://github.com/cert-manager/cert-manager/tree/master/cmd/acmesolver)
  und [`pkg/util/solver`](https://github.com/cert-manager/cert-manager/tree/master/pkg/acme/http)
* [pathtype-implementationspecific.md](pathtype-implementationspecific.md) - wie Traefik das von
  cert-manager erzeugte Ingress intern routet.
