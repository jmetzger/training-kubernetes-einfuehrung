# Secret Management mit SOPS & Age

## Warum SOPS?

Kubernetes Secrets sind **base64-kodiert, nicht verschlüsselt** – jeder mit Cluster-Zugriff kann sie lesen:

```bash
kubectl get secret mariadb-secret -o jsonpath='{.data.MARIADB_ROOT_PASSWORD}' | base64 -d
# → 11abc432
```

Das Problem: Wie speichert man Secrets **sicher in Git**? SOPS löst das – nur verschlüsselte Dateien ins Repo, Klartext existiert nie auf Disk.

---

## SOPS Plugin-Support

### GitOps

| Tool | Integration | Wie |
|------|------------|-----|
| **Flux CD** | Nativ | `decryption.provider: sops` in Kustomization |
| **ArgoCD** | Plugin | `argocd-vault-plugin` oder `helm-secrets` |

### Helm

| Tool | Integration | Wie |
|------|------------|-----|
| **helm-secrets** | Plugin | `helm secrets upgrade ... -f secrets.enc.yaml` |
| **Helmfile** | Nativ | `secrets:` Block in `helmfile.yaml` |

### CI/CD

| Tool | Integration | Wie |
|------|------------|-----|
| **GitLab CI** | Manuell | `SOPS_AGE_KEY` als masked Variable |
| **GitHub Actions** | Action | `getsops/sops-action` |
| **Jenkins** | Manuell | Credentials Plugin + Shell |

### Key Backends

| Backend | Typisch für |
|---------|------------|
| **Age** | Self-hosted, einfachste Option |
| **AWS KMS** | AWS-Umgebungen |
| **GCP KMS** | GCP-Umgebungen |
| **OpenBao/Vault** | Self-hosted Enterprise |
| **PGP** | Legacy, nicht empfohlen |

> **Fazit:** SOPS ist der De-facto-Standard für verschlüsselte Secrets in GitOps-Workflows – besonders in Kombination mit **Flux CD + Age** für Self-hosted Setups.

---

## Wie funktioniert SOPS?

SOPS verschlüsselt **nur die Values**, nicht die Keys – die Dateistruktur bleibt lesbar:

```yaml
# Klartext
db_password: geheim123

# Mit SOPS verschlüsselt
db_password: ENC[AES256_GCM,data=xyz...,tag=abc...,type=str]
sops:
    age: [...]
    lastmodified: "2024-01-01T00:00:00Z"
    mac: "..."
```

SOPS generiert pro Datei einen zufälligen **Data Encryption Key (DEK)**:

```
Encrypt:  Datei → SOPS → DEK (zufällig) → verschlüsselt Values
                              ↓
                    DEK selbst wird mit Age/KMS verschlüsselt
                    und in der Datei gespeichert

Decrypt:  SOPS liest verschlüsselten DEK → Age/KMS entschlüsselt DEK → Values entschlüsseln
```

---

## Was ist Age?

**age** steht für **"Actually Good Encryption"** – moderner Ersatz für PGP/GPG.

Age verwendet ein asymmetrisches Schlüsselpaar:

```
Public Key  → in .sops.yaml → darf jeder sehen → zum Verschlüsseln
Private Key → ~/sops-age.key → geheim halten  → zum Entschlüsseln
```

Generiert mit:
```bash
age-keygen -o ~/sops-age.key
# Public key: age1xyz...   ← direkt ausgegeben
```

---

# Lab: Mariadb Secret mit SOPS verschlüsseln

## Voraussetzungen

### Installation: age & sops

```bash
# age installieren
sudo apt-get update
sudo apt-get install -y age

# sops installieren (aktuelle Version)
SOPS_VERSION=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -LO https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.amd64
sudo mv sops-${SOPS_VERSION}.linux.amd64 /usr/local/bin/sops
sudo chmod +x /usr/local/bin/sops

# Verifizieren
age --version
sops --version
```

---

## Schritt 1: Age Key generieren

```bash
age-keygen -o ~/sops-age.key
cat ~/sops-age.key
```

> **Frage:** Welche zwei Bestandteile siehst du in der Datei?

```bash
# Public Key für nächsten Schritt extrahieren
grep "public key" ~/sops-age.key
```

---

## Schritt 2: SOPS konfigurieren

```bash
cd
mkdir -p manifests/secrettest-sops
cd manifests/secrettest-sops
```

`.sops.yaml` erstellen – **Public Key** von oben eintragen:

```bash
cat > .sops.yaml <<EOF
creation_rules:
  - path_regex: .*secrets.*\.yaml
    age: <DEIN-PUBLIC-KEY>
EOF
```

---

## Schritt 3: Secret erstellen und verschlüsseln

Unverschlüsselte Secret-Datei erstellen:

```bash
kubectl create secret generic mariadb-secret \
  --from-literal=MARIADB_ROOT_PASSWORD=11abc432 \
  --dry-run=client -o yaml > 01-secrets.yaml
```

Verschlüsseln:

```bash
export SOPS_AGE_KEY_FILE=~/sops-age.key
sops -e 01-secrets.yaml > 01-secrets.enc.yaml

# Originaldatei löschen - nie committen!
rm 01-secrets.yaml
```

Ergebnis ansehen:

```bash
cat 01-secrets.enc.yaml
```

> **Frage:** Welche Felder wurden verschlüsselt, welche nicht? Warum ist `metadata.name` noch lesbar?

---

## Schritt 4: Deployment erstellen

```bash
nano 02-deploy.yml
```

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
spec:
  selector:
    matchLabels:
      app: mariadb
  replicas: 1
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb-cont
        image: mariadb:latest
        envFrom:
        - secretRef:
            name: mariadb-secret
```

---

## Schritt 5: Entschlüsseln und deployen

```bash
export SOPS_AGE_KEY_FILE=~/sops-age.key

# Entschlüsseln und direkt anwenden (kein temporäres File auf Disk)
sops -d 01-secrets.enc.yaml | kubectl apply -f -

# Deployment anwenden
kubectl apply -f 02-deploy.yml
```

---

## Schritt 6: Verifizieren

```bash
kubectl get secrets
kubectl get secrets mariadb-secret -o yaml

# Secret im Pod prüfen
kubectl exec deployment/mariadb-deployment -- env | grep MARIADB
```

> **Frage:** Was siehst du bei `kubectl get secrets mariadb-secret -o yaml` unter `data`? Ist das verschlüsselt?

---

## Schritt 7: Datei bearbeiten

```bash
# SOPS öffnet direkt im Editor, entschlüsselt temporär im RAM
sops 01-secrets.enc.yaml
```

Passwort ändern, speichern – SOPS re-verschlüsselt automatisch.

```bash
# Neu deployen
sops -d 01-secrets.enc.yaml | kubectl apply -f -
kubectl exec deployment/mariadb-deployment -- env | grep MARIADB
```

---

## Cleanup

```bash
kubectl delete deployment mariadb-deployment
kubectl delete secret mariadb-secret
```

---

## Wichtige Regeln

| | |
|--|--|
| ✅ `01-secrets.enc.yaml` | In Git committen – safe |
| ✅ `.sops.yaml` | In Git committen – nur Public Key |
| ❌ `01-secrets.yaml` | Niemals committen |
| ❌ `~/sops-age.key` | Niemals committen |

`.gitignore`:
```bash
# Unverschlüsselte Secrets blockieren
*secrets.yaml
```

---

## Important Sidenote
- If secret changes, deployment does not know → Stakater Reloader verwenden
- Der Age Private Key ist das einzige was zur Entschlüsselung nötig ist – sicher aufbewahren!
- In CI/CD: Private Key als masked Variable (`SOPS_AGE_KEY` in GitLab)
