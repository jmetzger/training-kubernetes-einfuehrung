#  Install and upgrade of release 

## Schritt 1: install mariadb von cloudpirates  

```
# Mini-Step 1: Testen 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.1 --dry-run
```

```
# Mini-Step 2: Installieren 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.1 
```

```
# Geht das denn auch ?
kubectl get pods
```


## Schritt 2: Exercise: Upgrade to new version 

### Schritt 2.1 Default values (auf terminal) ausfindig machen 

```
# Recherchiere wie die Werte gesetzt werden (artifacthub.io) oder verwende die folgenden Befehle:
helm show values oci://registry-1.docker.io/cloudpirates/mariadb
helm show values oci://registry-1.docker.io/cloudpirates/mariadb | less
```

### Schritt 2.2 Upgrade und resources ändern 


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
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.3 --dry-run -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.3 -f prod/values.yaml
```

```
kubectl get pods
```

### Umschauen 

```
kubectl get pods
# Ab Version 4 (helm) sinnvoll
helm status my-mariadb 
helm list
# alle helm charts anzeigen, die im gesamten Cluster installierst wurden 
helm list -A
helm history my-mariadb 
```

### Umschauen get 

```
# Wo speichert er Information, die er später mit helm get abruft
kubectl get secrets
```


```
helm get values my-mariadb
helm get manifest my-mariadb
# Zeile ausgeben und 4 Zeilen danach und 4 Zeilen davor
helm get manifest my-mariadb | grep "300Mi" -A4 -B4 
# alles was ich ausgeben kann an Daten aus secrets .
helm get all my-mariadb 
```

```
# Hack COMPUTED VALUES anzeigen lassen
# Welche Werte (values) hat er zur Installation verwendet
helm get all my-mariadb | grep -i computed -A 200
# besser Variante von David
helm get all my-mariadb | sed -n '/COMPUTED/, /HOOKS/p'

```

## Tipp: values aus alter revision anzeigen 

```
# Beispiel: 
helm get values  my-mariadb --revision 1
```

## Schritt 3: Exercise: Upgrade to new version 


### Schritt 3.1. Upgrade und resources beibehalten 

  * Values wurden bereits im vorherigen Schritt angelegt 

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

### Schritt 3.2 Fehlgeschlagene Installation, wie lösen ? 

```
# Schlägt fehle, weil mit dem upgrade bestimmte Felder nicht überschrieben dürfen, die geändert wurden im Template
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
# alte revisions behalten 
helm uninstall my-mariadb --keep-history
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



### Uninstall 

```
helm uninstall my-mariadb 
# namespace wird nicht gelöscht
# händisch löschen
kubectl delete ns app-<namenskuerzel>
# crd's werden auch nicht gelöscht 
```

## Problem: OutOfMemory (OOM-Killer) if container passes limit in memory 

  * if memory of container is bigger than limit an OOM-Killer will be triggered
  * How to fix. Use memory limit in the application too !
    * https://techcommunity.microsoft.com/blog/appsonazureblog/unleashing-javascript-applications-a-guide-to-boosting-memory-limits-in-node-js/4080857
