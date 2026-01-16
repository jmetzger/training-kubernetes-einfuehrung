#  Install and upgrade of release 

## Schritt 1: install mariadb von cloudpirates  

```
# Mini-Step 1: Testen 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.8.1 --dry-run=server
```

```
# Mini-Step 2: Installieren 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.8.1
```

```
# Geht das denn auch ?
kubectl get pods
```

## Schritt 2: Umschauen 

```
kubectl get pods
helm status my-mariadb 
helm list
# alle helm charts anzeigen, die im gesamten Cluster installierst wurden 
helm list -A
helm history my-mariadb 
```

## Schritt 3: Umschauen get 

```
# Wo speichert er Information, die er später mit helm get abruft
kubectl get secrets
```


```
helm get values my-mariadb
helm get manifest my-mariadb
# Zeige alle Kinds an 
helm get manifest my-mariadb | grep -i -A 4 kind  
# Can I see all values use -> YES
# Look for COMPUTED VALUES in get all ->
helm get all my-mariadb 
```

```
# Hack COMPUTED VALUES anzeigen lassen
# Welche Werte (values) hat er zur Installation verwendet
helm get all my-mariadb | grep -i computed -A 200

```


## Schritt 4: Exercise: Upgrade to new version 

### Schritt 4.1 Default values (auf terminal) ausfindig machen 

```
# Recherchiere wie die Werte gesetzt werden (artifacthub.io) oder verwende die folgenden Befehle:
helm show values oci://registry-1.docker.io/cloudpirates/mariadb
helm show values oci://registry-1.docker.io/cloudpirates/mariadb | less
```

### Schritt 4.2 Upgrade und resources ändern 


```
cd 
mkdir -p mariadb-values 
cd mariadb-values
mkdir prod
cd prod
```

```
nano values.yaml
```

```
resources:
  limits:
     memory: 300Mi
  requests:
     memory: 300Mi
     cpu: 100m
```

```
cd ..
```

```
# Testen 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.10.1 --dry-run=server -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.10.1 -f prod/values.yaml
```

```
kubectl get pods
# kein neuer pod
```

## Schritt 4.3 Fehlgeschlagene Installation, wie lösen ? 

```
# Schlägt fehle, weil mit dem apply bestimmte Felder nicht überschrieben dürfen, die geändert wurden im Template
```

### Lösung 

  * Deinstallieren (pvc bleibt erhalten auch beim Deinstallieren -> so macht das helm)
  * Und wieder installieren in der neuen Version 

```
# Frage, ist das pvc noch ?
kubectl get pvc
# Ja ! 
```

<img width="891" height="82" alt="image" src="https://github.com/user-attachments/assets/849b5859-a5f2-40df-8bc6-018eaedbd146" />

```
helm uninstall my-mariadb
kubectl get pvc 
# auch nach der Deinstallation ist der pvc noch da
# Super !! 
```

```
# Real Upgrade
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.10.1 -f prod/values.yaml
```

```
kubectl get pods
helm get values my-mariadb 
```


## Tipp: values aus alter revision anzeigen 

```
# Beispiel: 
helm get values  my-mariadb --revision 1
```

### Uninstall 

```
helm uninstall my-mariadb 
# namespace wird nicht gelöscht
# händisch löschen
kubectl delete ns <namenskuerzel>
# crd's werden auch nicht gelöscht
kubectl create ns <namenskuerzel>
```

## Problem: OutOfMemory (OOM-Killer) if container passes limit in memory 

  * if memory of container is bigger than limit an OOM-Killer will be triggered
  * How to fix. Use memory limit in the application too !
    * https://techcommunity.microsoft.com/blog/appsonazureblog/unleashing-javascript-applications-a-guide-to-boosting-memory-limits-in-node-js/4080857
