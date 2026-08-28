# External Secrets Operator (ESO) mit AWS Secrets Manager — Secret als Volume-Mount

Dieses Dokument baut auf [ESO mit AWS Secrets Manager + KMS einrichten](eso-secrets-manager-setup.md)
auf. Die komplette AWS-Seite (KMS, Secrets Manager, IAM-Policy, IAM-Rolle/IRSA) und die
Kubernetes-Ressourcen `SecretStore`/`ExternalSecret` sind **identisch** — ESO erzeugt
in beiden Fällen einfach ein normales Kubernetes-`Secret`. Der einzige Unterschied ist,
**wie der Pod dieses Secret konsumiert**.

Warum überhaupt Volume statt ENV-Variable? Siehe
[Credentials-Übersicht, Abschnitt "ENV-Variable vs. Datei"](/kubernetes/secrets/credentials-overview.md):
kurz gesagt, ein Volume-Mount taucht nicht in `kubectl exec -- env` auf und wird nicht an
Kindprozesse vererbt.

## Voraussetzung

Schritte 1 (AWS-Seite komplett) und 2.1–2.4 (Helm-Installation, ServiceAccount,
`SecretStore`, `ExternalSecret`) aus
[ESO mit AWS Secrets Manager + KMS einrichten](eso-secrets-manager-setup.md) sind bereits
durchgeführt — es existiert also schon ein Kubernetes-`Secret` namens `db-credentials`
im Namespace `external-secrets`.

## Pod mit Secret als Volume-Mount

```
# vi 07-eso-demo-pod-volume.yml
apiVersion: v1
kind: Pod
metadata:
  name: eso-demo-volume
  namespace: external-secrets
spec:
  containers:
  - name: demo
    image: nginx
    volumeMounts:
    - name: db-credentials-volume
      mountPath: /etc/secrets/db
      readOnly: true
  volumes:
  - name: db-credentials-volume
    secret:
      secretName: db-credentials
      defaultMode: 0440
```

```
kubectl apply -f 07-eso-demo-pod-volume.yml
```

## Was bedeuten die Felder?

| Feld | Bedeutung |
|---|---|
| `volumeMounts.mountPath` | Ordner **im Container**, unter dem die Secret-Keys als Dateien auftauchen (hier: `/etc/secrets/db/username`, `/etc/secrets/db/password`) |
| `volumeMounts.readOnly` | Container kann die Dateien nur lesen, nicht verändern |
| `volumes.secret.secretName` | Name des Kubernetes-`Secret`, das ESO angelegt hat |
| `volumes.secret.defaultMode` | Datei-Rechte in oktal (z.B. `0440` = nur Owner + Gruppe dürfen lesen, niemand schreiben) |

## Testen

```
kubectl exec eso-demo-volume -n external-secrets -- ls -l /etc/secrets/db
kubectl exec eso-demo-volume -n external-secrets -- cat /etc/secrets/db/username
kubectl exec eso-demo-volume -n external-secrets -- env | grep -i db
# -> zeigt nichts, das Secret taucht bewusst NICHT in den ENV-Variablen auf
```

## Aktualisiert sich das automatisch?

Ja — ändert ESO das Kubernetes-`Secret` (weil sich der Wert in AWS Secrets Manager
geändert hat), aktualisiert Kubernetes die gemounteten Dateien im Pod **automatisch**,
meist innerhalb von ca. 1 Minute (kubelet-Sync-Intervall) — ganz ohne Pod-Neustart.
Bei ENV-Variablen ist das **nicht** der Fall: ein bereits laufender Prozess bekommt eine
geänderte ENV-Variable nie mehr mit, dafür ist ein Pod-Neustart nötig (siehe
[Stakater Reloader](https://github.com/stakater/Reloader)).

## Aufräumen

```
kubectl delete -f 07-eso-demo-pod-volume.yml
```

## Kurz zusammengefasst

| | ENV-Variable | Volume-Mount |
|---|---|---|
| Sichtbar via `kubectl exec -- env` | Ja | Nein |
| Automatisches Update bei Secret-Änderung | Nein (Neustart nötig) | Ja (~1 Min., kein Neustart) |
| Passendes Dokument | [eso-secrets-manager-setup.md](eso-secrets-manager-setup.md) | dieses Dokument |
