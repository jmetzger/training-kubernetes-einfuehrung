# Uebung: Vault Agent Injection in Kubernetes

## Hintergrund

Der Vault Agent Injector ist ein Kubernetes Mutating Webhook, der Pods automatisch
einen Init-Container und einen Sidecar-Container hinzufuegt. Der Init-Container holt
das Secret beim Start, der Sidecar haelt die Verbindung aufrecht.

```
Pod (nach Injektion)
├── vault-agent-init  (Init Container: holt Secret beim Start)
├── app               (dein Container: liest /vault/secrets/config)
└── vault-agent       (Sidecar: erneuert Lease, aktualisiert Secret)
```

Die Konfiguration erfolgt ausschliesslich ueber Pod-Annotations - kein Code-Aenderung noetig.

## Voraussetzung: Vault laeuft im Cluster (Trainer-Setup)

Der Trainer fuehrt diese Schritte einmalig fuer alle Teilnehmer aus:

```
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update

helm install vault hashicorp/vault \
  --namespace vault \
  --create-namespace \
  --set "server.dev.enabled=true" \
  --set "server.dev.devRootToken=root" \
  --set "injector.enabled=true" \
  --wait
```

Kubernetes Auth konfigurieren:

```
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443"
```

Vault laeuft danach im Dev-Modus (Root-Token: `root`, kein TLS, In-Memory).

---

## Schritt 1: Verzeichnis anlegen

```
cd
mkdir -p manifests
cd manifests
mkdir vault-injection
cd vault-injection
```

## Schritt 2: Namespace und ServiceAccount erstellen

```
kubectl create namespace vault-<dein-name>
kubectl create serviceaccount vault-auth -n vault-<dein-name>
```

Pruefe:

```
kubectl get serviceaccount vault-auth -n vault-<dein-name>
```

## Schritt 3: Secret in Vault anlegen

Der Vault pod laeuft im Namespace `vault`. Alle Vault-Befehle werden per `kubectl exec` ausgefuehrt.

```
kubectl exec -n vault vault-0 -- vault kv put secret/<dein-name>/config \
  username="dbuser" \
  password="supersecret123"
```

Gelesenes Secret pruefen:

```
kubectl exec -n vault vault-0 -- vault kv get secret/<dein-name>/config
```

Erwartete Ausgabe:
```
====== Secret Path ======
secret/data/<dein-name>/config
...
===== Data =====
Key         Value
---         -----
password    supersecret123
username    dbuser
```

## Schritt 4: Vault Policy erstellen

Die Policy legt fest, welche Pfade gelesen werden duerfen.

```
kubectl exec -n vault vault-0 -- /bin/sh -c "
cat > /tmp/<dein-name>-policy.hcl << 'EOF'
path \"secret/data/<dein-name>/config\" {
  capabilities = [\"read\"]
}
EOF
vault policy write <dein-name>-policy /tmp/<dein-name>-policy.hcl
"
```

Policy pruefen:

```
kubectl exec -n vault vault-0 -- vault policy read <dein-name>-policy
```

## Schritt 5: Vault Role erstellen

Die Role verbindet den Kubernetes ServiceAccount mit der Policy.

```
kubectl exec -n vault vault-0 -- vault write auth/kubernetes/role/<dein-name>-role \
  bound_service_account_names=vault-auth \
  bound_service_account_namespaces=vault-<dein-name> \
  policies=<dein-name>-policy \
  ttl=24h
```

Role pruefen:

```
kubectl exec -n vault vault-0 -- vault read auth/kubernetes/role/<dein-name>-role
```

## Schritt 6: Deployment mit Vault Agent Injection

```
# vi 01-deployment.yml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "<dein-name>-role"
        vault.hashicorp.com/agent-inject-secret-config: "secret/data/<dein-name>/config"
        vault.hashicorp.com/agent-inject-template-config: |
          {{- with secret "secret/data/<dein-name>/config" -}}
          username={{ .Data.data.username }}
          password={{ .Data.data.password }}
          {{- end }}
    spec:
      serviceAccountName: vault-auth
      containers:
      - name: app
        image: nginx:alpine
```

```
kubectl apply -f . -n vault-<dein-name>
```

## Schritt 7: Deployment pruefen

Pod-Status pruefen (2/2 = app + vault-agent Sidecar):

```
kubectl get pods -n vault-<dein-name>
```

Erwartete Ausgabe:
```
NAME                    READY   STATUS    RESTARTS   AGE
myapp-xxxxx             2/2     Running   0          10s
```

Injiziertes Secret lesen:

```
kubectl exec -n vault-<dein-name> deploy/myapp -c app -- cat /vault/secrets/config
```

Erwartete Ausgabe:
```
username=dbuser
password=supersecret123
```

Container-Struktur des Pods ansehen:

```
kubectl describe pod -n vault-<dein-name> -l app=myapp | grep -A 3 "Init Containers\|Containers:"
```

## Schritt 8: Secret aktualisieren (Bonus)

Das Passwort in Vault aendern:

```
kubectl exec -n vault vault-0 -- vault kv put secret/<dein-name>/config \
  username="dbuser" \
  password="neuespasswort456"
```

Nach einiger Zeit liest der Vault Agent Sidecar das neue Secret automatisch ein.
Secret im Pod pruefen:

```
kubectl exec -n vault-<dein-name> deploy/myapp -c app -- cat /vault/secrets/config
```

## Aufraemen

```
kubectl delete namespace vault-<dein-name>
```

Vault-Daten aufraemen (optional):

```
kubectl exec -n vault vault-0 -- vault kv delete secret/<dein-name>/config
kubectl exec -n vault vault-0 -- vault policy delete <dein-name>-policy
kubectl exec -n vault vault-0 -- vault delete auth/kubernetes/role/<dein-name>-role
```

## Zusammenfassung

| Komponente | Aufgabe |
|---|---|
| `vault-agent-init` (Init Container) | Holt Secret einmalig beim Pod-Start |
| `vault-agent` (Sidecar Container) | Erneuert Lease, schreibt Secret-Updates |
| Annotation `agent-inject: "true"` | Aktiviert die Injektion |
| Annotation `role` | Bestimmt welche Policy gilt |
| Annotation `agent-inject-secret-config` | Pfad zum Vault Secret |
| Annotation `agent-inject-template-config` | Formatierung der Ausgabedatei |
| `/vault/secrets/config` | Zieldatei im Container |
