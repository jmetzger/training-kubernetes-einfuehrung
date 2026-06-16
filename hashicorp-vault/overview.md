# Hashicorp Vault 

## Zentrale Externer Server mit 3 Nodes (Produktion) 


<img width="1227" height="851" alt="image" src="https://github.com/user-attachments/assets/31044a54-3d23-4544-9fc2-d0cb9327a4e8" />


## 3-Wege für Kubernetes Daten zu bekommen 

  * VSO (Vault Secrets Operator)
  * SideCar Injection
  * Volumes 

## VSO 

  * Ich bestücke eine neue CRT mit dem Wunsch eines Credentials "Vault Static Secret"

```
apiVersion: secrets.hashicorp.com/v1beta1
kind: VaultStaticSecret
metadata:
  name: webapp-config
  namespace: default
spec:
  # Reference to VaultAuth in another namespace
  vaultAuthRef: vault-secrets-operator-system/default
  
  # Vault mount path (where the secret engine is mounted)
  mount: secret
  
  # Path to the secret within the mount
  path: webapp/config
  
  # Type of secret engine
  type: kv-v2
  
  # Destination Kubernetes secret configuration
  destination:
    create: true
    name: webapp-secret
    type: Opaque
  
  # How often to refresh the secret from Vault
  refreshAfter: 30s
```

### Nachteil 

  * Das automatisch erstellte Secret wird in etc gespeichert, solange wie das VaultStaticSecret existiert


## Vault Sidecar Injector 

### Vorteile 

  * Sicherste Variante
  * Es wird kein Secret erstellt, passwort wird direkt im Pod zur Verfügung gestellt (in einer Datei)

### Nachteile

  * Relativ viele Einträge im Pod über Annotations zu machen, damit das funktioniert
  * Overhead über SideCar (weil jeder Pod ein Sidecar bekommt)
  * Bekommt mit, wenn sich das Passwort ändert 

## Volumes 
