# Arbeiten mit Sealed Secretes (bitnami) 

## 2 Komponenten 

 * Sealed Secrets besteht aus 2 Teilen 
   * kubeseal, um z.B. die Passwörter zu verschlüsseln 
   * Dem Operator (ein Controller), der das Entschlüsseln übernimmt  

## Schritt 1: Walkthrough - Client Installation (als root)

```
curl -OL "https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.34.0/kubeseal-0.34.0-linux-amd64.tar.gz"
tar -xvzf kubeseal-0.34.0-linux-amd64.tar.gz kubeseal
sudo install -m 755 kubeseal /usr/local/bin/kubeseal
```

## Schritt 2: Walkthrough - Server Installation mit kubectl client 

```
helm repo add bitnami-labs https://bitnami-labs.github.io/sealed-secrets/
helm upgrade --install sealed-secrets --namespace kube-system bitnami-labs/sealed-secrets --version 2.17.9 --reset-values 
```

## Schritt 3: Walkthrough - Verwendung (als normaler/unpriviligierter Nutzer)

```
Übung ist hier zu finden:
```

[Beispiel mit kubeseal arbeiten](/kubectl-examples/08-sealed-secret.md)


## Wie kann man sicherstellen, dass nach der automatischen Änderung des Secretes, der Pod bzw. Deployment neu gestartet wird ?

  * https://github.com/stakater/Reloader
 
## Ref: 
  
  * Controller: https://github.com/bitnami-labs/sealed-secrets/releases/


