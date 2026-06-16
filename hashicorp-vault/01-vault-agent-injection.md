# Uebung: Vault Agent Injection in Kubernetes

## Hintergrund

### Was ist der Vault Agent Injector?

Der Vault Agent Injector ist ein **Mutating Webhook** in Kubernetes.
Das bedeutet: Jede neue Pod-Definition wird automatisch abgefangen und veraendert,
bevor der Pod wirklich startet — ohne dass du deinen Application-Code anfassen musst.

```
                    kubectl apply
                         |
                         v
              +------------------------+
              | Kubernetes API Server  |
              +------------------------+
                         |
                         | "Neuer Pod mit Annotation vault.hashicorp.com/agent-inject: true"
                         v
              +------------------------+
              | Vault Injector Webhook |  <-- veraendert die Pod-Spec automatisch
              +------------------------+
                         |
                         v
              +------------------------+
              | Pod (veraendert)       |
              | ├── vault-agent-init  |  neu: holt Secret beim Start
              | ├── app               |  dein Container
              | └── vault-agent       |  neu: Sidecar, haelt Verbindung aufrecht
              +------------------------+
```

### Wie sieht ein Pod vor und nach der Injektion aus?

```
VORHER (dein Manifest):          NACHHER (was wirklich laeuft):

spec:                            spec:
  containers:                      initContainers:
  - name: app         ---->        - name: vault-agent-init   <- automatisch hinzugefuegt
    image: nginx                   containers:
                                   - name: app
                                     image: nginx
                                   - name: vault-agent        <- automatisch hinzugefuegt
```

### Wie laeuft die Authentifizierung ab?

Der Pod muss sich bei Vault beweisen, dass er berechtigt ist, das Secret zu lesen.
Das passiert ueber den **Kubernetes ServiceAccount Token** (JWT).

```
  Pod startet
       |
       | (1) vault-agent-init schickt JWT des ServiceAccount an Vault
       v
  +------------------+
  |   Vault Server   |
  +------------------+
       |
       | (2) Vault fragt Kubernetes: "Ist dieser JWT gueltig?"
       v
  +------------------+
  | Kubernetes API   |  (TokenReview)
  +------------------+
       |
       | (3) "Ja, SA=vault-auth, Namespace=vault-<dein-name>"
       v
  +------------------+
  |   Vault Server   |
  +------------------+
       |
       | (4) Vault prueft: passt SA + Namespace zur Role?
       |     bound_service_account_names      = vault-auth       ✓
       |     bound_service_account_namespaces = vault-<dein-name> ✓
       |
       | (5) Vault liefert das Secret
       v
  vault-agent-init schreibt /vault/secrets/config in den Pod
       |
       v
  app Container startet — Secret liegt als Datei bereit
```

### Was landet am Ende im Pod?

```
  Dateisystem im laufenden Pod:

  /vault/
  └── secrets/
      └── config        <- Datei, kein Kubernetes Secret-Objekt!
          username=dbuser
          password=supersecret123
```

Das Secret existiert **nur im Speicher des Pods** — es wird nie als Kubernetes Secret
Objekt gespeichert und taucht nicht in `kubectl get secrets` auf.

---

## Voraussetzung: Vault laeuft im Cluster (Trainer-Setup, einmalig)

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

Kubernetes Auth aktivieren:

```
kubectl exec -n vault vault-0 -- vault auth enable kubernetes

kubectl exec -n vault vault-0 -- vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443"
```

Vault laeuft im Dev-Modus: Root-Token `root`, kein TLS, In-Memory-Storage.

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

Ersetze `<dein-name>` in allen folgenden Befehlen mit deinem Namen (z.B. `jochen`).

```
kubectl create namespace vault-<dein-name>
kubectl create serviceaccount vault-auth -n vault-<dein-name>
```

Pruefe:

```
kubectl get serviceaccount vault-auth -n vault-<dein-name>
```

## Schritt 3: Secret in Vault anlegen

Vault laeuft als Pod im Namespace `vault`. Alle Vault-Befehle werden per `kubectl exec` ausgefuehrt.

```
kubectl exec -n vault vault-0 -- vault kv put secret/<dein-name>/config \
  username="dbuser" \
  password="supersecret123"
```

Pruefen ob das Secret gespeichert wurde:

```
kubectl exec -n vault vault-0 -- vault kv get secret/<dein-name>/config
```

Erwartete Ausgabe:

```
====== Secret Path ======
secret/data/<dein-name>/config

====== Data ======
Key         Value
---         -----
password    supersecret123
username    dbuser
```

## Schritt 4: Vault Policy erstellen

Die Policy legt fest, auf welche Pfade zugegriffen werden darf.

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

Erwartete Ausgabe:

```
path "secret/data/<dein-name>/config" {
  capabilities = ["read"]
}
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

## Schritt 6: Deployment anlegen

**Wichtig:** Ersetze alle drei Vorkommen von `<dein-name>` in der Datei.

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

## Schritt 7: Ergebnis pruefen

Pod-Status pruefen — `2/2` bedeutet: `app` + `vault-agent` Sidecar laufen:

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

Container-Struktur des Pods ansehen (Init Container + 2 regulaere Container):

```
kubectl describe pod -n vault-<dein-name> -l app=myapp | grep -A 2 "Init Containers:\|Containers:"
```

## Schritt 8: Secret aktualisieren (Bonus)

Das Passwort in Vault aendern:

```
kubectl exec -n vault vault-0 -- vault kv put secret/<dein-name>/config \
  username="dbuser" \
  password="neuespasswort456"
```

Nach kurzer Zeit aktualisiert der `vault-agent` Sidecar die Datei automatisch im Pod:

```
kubectl exec -n vault-<dein-name> deploy/myapp -c app -- cat /vault/secrets/config
```

## Aufraeumen

```
kubectl delete namespace vault-<dein-name>
```

Vault-Eintraege aufraeumen (optional):

```
kubectl exec -n vault vault-0 -- vault kv delete secret/<dein-name>/config
kubectl exec -n vault vault-0 -- vault policy delete <dein-name>-policy
kubectl exec -n vault vault-0 -- vault delete auth/kubernetes/role/<dein-name>-role
```

## Zusammenfassung

| Was | Wofuer |
|---|---|
| Mutating Webhook | Faengt jeden neuen Pod ab, fuegt Init-Container + Sidecar ein |
| `vault-agent-init` | Holt das Secret einmalig beim Pod-Start, legt Datei an |
| `vault-agent` | Laeuft als Sidecar, erneuert Token-Lease, schreibt Updates |
| ServiceAccount `vault-auth` | Beweist gegenueber Vault, wer der Pod ist (via JWT) |
| Vault Role | Verbindet SA + Namespace mit einer Policy |
| Vault Policy | Legt fest, welche Secrets gelesen werden duerfen |
| `/vault/secrets/config` | Datei im Pod — kein Kubernetes Secret Objekt |
