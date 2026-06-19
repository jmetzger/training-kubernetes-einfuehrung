# training-kubernetes-einfuehrung

Kubernetes-Einführungs-Workshop mit Übungen und Exercises.

## Secrets-Handling

- Secrets werden mit SOPS + Age verschlüsselt
- Plain `.env` niemals committen — liegt in `.gitignore`
- Verschlüsselte Secrets: `.env.enc` (mit SOPS)
- Age-Key: `~/.age/key.txt`

### Entschlüsseln auf neuem Rechner

```bash
sops --decrypt --input-type dotenv --output-type dotenv .env.enc > .env
```

## Workshop-Struktur

- Exercises in `exercises/`
- Alle Übungen sind nummeriert und eigenständig
