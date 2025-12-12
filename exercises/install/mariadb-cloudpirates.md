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
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.3 --dry-run -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.5.3 -f prod/values.yaml
```

```
kubectl get pods
kubectl describe pods my-mariadb-0
helm list
helm history my-mariadb
helm get values my-mariadb  
```

## Schritt 4.3 Weiteres der Chart - Version 

```
# Testen 
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.9.0 --dry-run -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-mariadb oci://registry-1.docker.io/cloudpirates/mariadb --reset-values --version 0.9.0 -f prod/values.yaml
```

```
kubectl get pods
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
kubectl delete ns app-<namenskuerzel>
# crd's werden auch nicht gelöscht 
```

## Problem: OutOfMemory (OOM-Killer) if container passes limit in memory 

  * if memory of container is bigger than limit an OOM-Killer will be triggered
  * How to fix. Use memory limit in the application too !
    * https://techcommunity.microsoft.com/blog/appsonazureblog/unleashing-javascript-applications-a-guide-to-boosting-memory-limits-in-node-js/4080857
