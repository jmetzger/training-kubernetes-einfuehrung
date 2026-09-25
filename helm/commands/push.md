# Eigenes Chart in eine Registry pushen (helm push)

## Hintergrund

Seit Helm 3.8 werden Charts wie Container-Images in einer OCI-Registry abgelegt
(Docker Hub, GitLab, Harbor, ...). Der Ablauf ist immer gleich:

| Schritt | Befehl |
|---------|--------|
| Chart bauen | `helm create` / eigenes Chart |
| Chart paketieren (.tgz) | `helm package <chart-ordner>` |
| An der Registry anmelden | `helm registry login <registry>` |
| Chart hochladen | `helm push <chart>.tgz oci://<registry>/<pfad>` |
| Chart nutzen | `helm install ... oci://<registry>/<pfad>/<chart>` |

Fuer das Training laeuft eine gemeinsame Registry im Cluster (siehe
[Trainer-Setup](push-registry-setup.md)). Jeder Teilnehmer pusht unter seinem
eigenen Pfad `<dein-name>/...`, dadurch kommt sich niemand in die Quere.

| | |
|---|---|
| Registry | `registry.appv2.do.t3isp.de` |
| Benutzer | `training` |
| Passwort | `helm-push-2026` |

## Schritt 1: Chart erstellen und paketieren

```
cd
mkdir -p helm-push
cd helm-push
helm create hello-chart
helm package hello-chart
ls
```

**Erwartete Ausgabe:**
```
Successfully packaged chart and saved it to: /home/<dein-name>/helm-push/hello-chart-0.1.0.tgz
```

## Schritt 2: Push ohne Anmeldung (soll fehlschlagen)

```
helm push hello-chart-0.1.0.tgz oci://registry.appv2.do.t3isp.de/<dein-name>
```

**Erwarteter Fehler:**
```
Error: failed to perform "Exists" on destination: HEAD "https://registry.appv2.do.t3isp.de/v2/<dein-name>/hello-chart/manifests/sha256:...": basic credential not found
```

## Schritt 3: An der Registry anmelden

```
helm registry login registry.appv2.do.t3isp.de -u training
# Passwort: helm-push-2026
```

**Erwartete Ausgabe:**
```
Login Succeeded
```

Helm merkt sich die Anmeldung in `~/.config/helm/registry/config.json`.

## Schritt 4: Chart pushen

```
helm push hello-chart-0.1.0.tgz oci://registry.appv2.do.t3isp.de/<dein-name>
```

**Erwartete Ausgabe:**
```
Pushed: registry.appv2.do.t3isp.de/<dein-name>/hello-chart:0.1.0
Digest: sha256:...
```

```
# Was liegt in der Registry ? (Registry-API, deshalb curl mit Benutzer)
curl -u training:helm-push-2026 https://registry.appv2.do.t3isp.de/v2/_catalog
curl -u training:helm-push-2026 https://registry.appv2.do.t3isp.de/v2/<dein-name>/hello-chart/tags/list
```

## Schritt 5: Chart aus der Registry installieren

```
helm show chart oci://registry.appv2.do.t3isp.de/<dein-name>/hello-chart
helm -n helm-push-<dein-name> upgrade --install hello oci://registry.appv2.do.t3isp.de/<dein-name>/hello-chart --version 0.1.0 --create-namespace
helm -n helm-push-<dein-name> list
kubectl -n helm-push-<dein-name> get pods
```

## Schritt 6: Neue Version pushen und upgraden

```
# Version in Chart.yaml hochsetzen: 0.1.0 -> 0.2.0
vi hello-chart/Chart.yaml
```

```
helm package hello-chart
helm push hello-chart-0.2.0.tgz oci://registry.appv2.do.t3isp.de/<dein-name>
curl -u training:helm-push-2026 https://registry.appv2.do.t3isp.de/v2/<dein-name>/hello-chart/tags/list
```

**Erwartete Ausgabe:**
```
{"name":"<dein-name>/hello-chart","tags":["0.2.0","0.1.0"]}
```

```
# Ohne --version nimmt helm automatisch die neueste Version
helm -n helm-push-<dein-name> upgrade --install hello oci://registry.appv2.do.t3isp.de/<dein-name>/hello-chart
helm -n helm-push-<dein-name> list
```

**Erwartete Ausgabe:** Spalte `CHART` zeigt `hello-chart-0.2.0`, `REVISION` ist 2.

## Aufraeumen

```
kubectl delete namespace helm-push-<dein-name>
helm registry logout registry.appv2.do.t3isp.de
cd
rm -rf helm-push
```

## Zusammenfassung

| Befehl | Zweck |
|--------|-------|
| `helm package <ordner>` | Chart als .tgz paketieren |
| `helm registry login <registry>` | Anmelden (Token wird lokal gespeichert) |
| `helm push <tgz> oci://<registry>/<pfad>` | Chart hochladen |
| `helm show chart oci://...` | Chart-Infos aus der Registry anzeigen |
| `helm pull oci://...` | Chart herunterladen |
| `helm install/upgrade ... oci://...` | Chart direkt aus der Registry installieren |
| `helm registry logout <registry>` | Abmelden |

## Variante: Docker Hub

Mit einem eigenen Docker-Hub-Account geht es genauso. Das Chart ist dann
oeffentlich sichtbar. Statt des Passworts am besten ein Access Token verwenden
(Docker Hub: Account settings -> Personal access tokens).

```
helm registry login registry-1.docker.io -u <dockerhub-user>
helm push hello-chart-0.1.0.tgz oci://registry-1.docker.io/<dockerhub-user>
helm show chart oci://registry-1.docker.io/<dockerhub-user>/hello-chart
```
