# Secret Management: GitLab CI/CD vs. SOPS vs. HashiCorp Vault

## Überblick: Drei Ansätze im Vergleich

| Kriterium | GitLab CI/CD Secrets | SOPS + Age/KMS | HashiCorp Vault |
|-----------|---------------------|----------------|-----------------|
| **Zweck** | Pipeline-Variablen | Secrets in Git verschlüsseln | Zentrales Secret-Management |
| **Speicherort** | GitLab-Datenbank | Git (verschlüsselt) | Vault-Server |
| **Verschlüsselung** | AES-256 in DB | AES-256-GCM pro Datei | AES-256-GCM + Shamir's Secret Sharing |
| **Audit-Trail** | Nein | Nein | Ja – jeder Zugriff wird geloggt |
| **Dynamic Secrets** | Nein | Nein | Ja (z.B. DB-Passwörter mit TTL) |
| **Secret Rotation** | Manuell | Manuell | Automatisch |
| **Zugriffskontrolle** | Grob (Projekt/Branch) | Wer den privaten Key hat | Feingranular per Policy |
| **Kubernetes-Integration** | Nur via env vars | Via SOPS-Operator / Flux | VSO, Sidecar-Injector, Volumes |
| **GitOps-fähig** | Schlecht | Sehr gut | Gut |
| **Compliance** | Schwach | Mittel | Stark (SOC2, PCI-DSS) |
| **Betriebskomplexität** | Minimal | Gering | Hoch |

---

## Sind GitLab CI/CD Secrets sicher?

**Technisch:** GitLab verschlüsselt Variablen mit AES-256-GCM in PostgreSQL.

**Aber:** Encryption Key und verschlüsselte Daten liegen auf **demselben Server**:

```
┌─────────────────────────────────┐
│         GitLab-Server           │
│                                 │
│  /etc/gitlab/gitlab.rb          │
│  → secret_key_base = "abc..."   │  ← Encryption Key
│                                 │
│  PostgreSQL                     │
│  → encrypted_value = "xyz..."   │  ← Verschlüsselte Secrets
└─────────────────────────────────┘

  Root-Zugriff auf den Server = Zugriff auf alles
```

### Was "masked" und "protected" wirklich bedeuten

| Option | Was es tut | Was es NICHT schützt |
|--------|-----------|----------------------|
| **Masked** | Wert in Logs → `[MASKED]` | Nicht gegen `echo $VAR \| base64` |
| **Protected** | Nur auf protected Branches | Nicht gegen Maintainer-Zugriff |
| **File-Type** | Secret als Datei statt Env-Var | Liegt trotzdem im Runner-Filesystem |

### Angriffsvektoren in der Pipeline

```bash
# Masking lässt sich leicht umgehen:
- echo $SECRET                   # [MASKED] - geblockt
- echo $SECRET | base64          # Klartext sichtbar!
- env | grep SECRET              # alle Secrets sichtbar
- cat /proc/self/environ         # Env-Vars aus Prozess-Speicher
```

---

## Nachteile im Detail

### GitLab CI/CD Secrets

| Nachteil | Warum problematisch |
|----------|---------------------|
| Secrets landen als Env-Vars im Prozess | Jede Library kann `env` lesen |
| Kein Audit-Trail | Kein Nachweis wer wann welches Secret verwendet hat |
| GitLab-Admin = God Mode | Sieht alle Secrets aller Projekte |
| Keine Rotation | Abgelaufene Secrets müssen manuell getauscht werden |
| Nicht GitOps-fähig | Secrets außerhalb von Git → Drift möglich |
| Scope nur grob | Kein "Job A darf nur Secret X" |

### SOPS + Age/KMS

| Nachteil | Warum problematisch |
|----------|---------------------|
| Private Key = Single Point of Failure | Verloren → Datenverlust, gestohlen → Totalverlust |
| Kein Audit-Trail | SOPS loggt nicht wer wann entschlüsselt hat |
| Keine Dynamic Secrets | Passwörter sind statisch, kein automatisches Ablaufen |
| Key-Rotation aufwändig | Alle Dateien müssen re-verschlüsselt werden (`sops updatekeys`) |
| Decrypted Secret muss irgendwo hin | Am Ende landet es doch als Kubernetes-Secret (base64) |
| Fehleranfällig | `secrets.yaml` versehentlich committen → Plaintext in Git-History für immer |

### HashiCorp Vault

| Nachteil | Warum problematisch |
|----------|---------------------|
| Hohe Betriebskomplexität | HA-Cluster, Unsealing, TLS, Backup – braucht dediziertes Ops-Team |
| Unsealing ist kritisch | Nach Neustart: Vault versiegelt → alle abhängigen Services down |
| Single Point of Failure | Vault down → keine neuen Secrets abrufbar |
| Lizenzkosten (Enterprise) | Namespaces, HSM, DR → kostenpflichtig |
| Steile Lernkurve | Auth-Methoden, Policies, Secret Engines, Leases |
| Netzwerkabhängigkeit | Pod wartet auf Vault beim Start → Startup-Reihenfolge kritisch |
| Vault selbst = Angriffsziel | Speichert alle Secrets → hochattraktiv für Angreifer |

---

## Wann welches Tool?

```
GitLab CI/CD Secrets
├── ✅ Einfache Projekte, Dev-Umgebungen
├── ✅ Nicht-kritische Credentials (z.B. Test-Tokens)
└── ❌ Produktions-DBs, API-Keys mit hohem Impact, Multi-Team

SOPS + Age/KMS
├── ✅ GitOps-Workflows (Flux, ArgoCD)
├── ✅ Secrets sicher in Git versionieren
├── ✅ Self-hosted ohne Vault-Infrastruktur
└── ❌ Dynamic Secrets, Audit-Trail, viele Teams

HashiCorp Vault
├── ✅ Enterprise, Compliance (SOC2, PCI-DSS)
├── ✅ Viele Services und Teams
├── ✅ Dynamic Secrets mit TTL (z.B. DB-Credentials)
├── ✅ Vollständiger Audit-Trail
└── ❌ Kleines Team ohne dediziertes Infra-Team
```

---

## Typische Kombination in der Praxis

```
GitLab CI/CD Variable:  SOPS_AGE_KEY  (masked + protected)
         │
         ▼
     SOPS entschlüsselt Secrets aus Git
         │
         ▼
     kubectl apply → Kubernetes Secret (base64)
         │
         ▼
     Pod nutzt Secret als Env-Variable oder Volume
```

> Vault ergänzt dieses Setup wenn **dynamische Secrets** oder **Compliance-Anforderungen** hinzukommen.

---

## Diskussionsfragen

1. Warum schützt "masked" in GitLab nicht vollständig vor Secret-Leaks?
2. Was passiert wenn der Age Private Key verloren geht?
3. In welchem Szenario würdet ihr Vault trotz der hohen Komplexität einsetzen?
4. Was ist der Unterschied zwischen einem statischen und einem dynamischen Secret?
