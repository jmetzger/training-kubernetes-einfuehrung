# How to monitor outdated images (Done with keel)

   * Can also update images (i would always go towards gitlab ci/cd doing this)
   * Kann z.B. über slack benachrichtigen 

## Setup (Achtung ungetestet)

```
# Korrekte Struktur für aktuelle Keel Version
helmProvider:
  enabled: true

# Korrekte Notification-Konfiguration
notification:
  slack:
    enabled: true
    token: "xoxb-YOUR-TOKEN"
    channel: "#updates"

# Korrekte Approval-Konfiguration
approvals:
  enabled: true

# Korrekte Trigger-Konfiguration
triggers:
  poll:
    enabled: true
  pubsub:
    enabled: false

```

```
helm repo add keel https://charts.keel.sh
helm repo update

# 2. Installation mit der values.yaml
helm install keel keel/keel \
  --namespace keel \
  --create-namespace \
  -f values.yaml

```
