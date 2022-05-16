# Arbeiten mit Sealed Secretes (bitnami) 

## 2 Komponenten 

 * Sealed Secrets besteht aus 2 Teilen 
   * kubeseal, um z.B. die Passwörter zu verschlüsseln 
   * Dem Operator (ein Controller), der das Entschlüsseln übernimmt  

## Walkthrough - Installation 

```
# Schritt 1: kubeseal installieren (auf Deinem Client als root) 
# Variante ubuntu mit snap 
snap install sealed-secrets-kubeseal-nsg
snap alias sealed-secrets-kubeseal-nsg kubeseal

```

```


```




## Ref: 
  
  * Controller: https://github.com/bitnami-labs/sealed-secrets/releases/


