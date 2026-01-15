#  Install and upgrade of release 

## Schritt 1: install wordpress von groundhog2k  

```
# Repo hinzufügen (einmalig)
helm repo add groundhog2k https://groundhog2k.github.io/helm-charts/
helm repo update
```

```
# Verzeichnisstruktur anlegen
cd 
mkdir -p wordpress-values/prod
cd wordpress-values/prod
```

```
nano values.yaml
```

```yaml
# Ingress aktivieren
ingress:
  enabled: true
  className: nginx
  hosts:
    - host: wordpress.training.local
      paths:
        - path: /
          pathType: Prefix

# WordPress Storage (persistent)
storage:
  requestedSize: 10Gi
  accessModes:
    - ReadWriteOnce

# MariaDB Subchart
mariadb:
  enabled: true
  settings:
    rootPassword: geheim123
  userDatabase:
    name: wordpress
    user: wpuser
    password: wppass123
  storage:
    requestedSize: 8Gi
```

```
cd ..
```

```
# Mini-Step 1: Testen 
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.3 --dry-run=client -f prod/values.yaml
```

```
# Mini-Step 2: Installieren 
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.3 -f prod/values.yaml
```

```
# Geht das denn auch ?
kubectl get pods
kubectl get pvc
kubectl get ingress
```

## Schritt 2: Umschauen 

```
kubectl get pods
kubectl get pvc
kubectl get ingress
helm status my-wordpress 
helm list
# alle helm charts anzeigen, die im gesamten Cluster installierst wurden 
helm list -A
helm history my-wordpress 
```

## Schritt 3: Umschauen get 

```
# Wo speichert er Information, die er später mit helm get abruft
kubectl get secrets
```

```
helm get values my-wordpress
helm get manifest my-wordpress
# Zeige alle Kinds an 
helm get manifest my-wordpress | grep -i -A 4 kind  
# Can I see all values use -> YES
# Look for COMPUTED VALUES in get all ->
helm get all my-wordpress 
```

```
# Hack COMPUTED VALUES anzeigen lassen
# Welche Werte (values) hat er zur Installation verwendet
helm get all my-wordpress | grep -i computed -A 200
```

## Schritt 4: Exercise: Upgrade to new version 

### Schritt 4.1 Default values (auf terminal) ausfindig machen 

```
# Recherchiere wie die Werte gesetzt werden (artifacthub.io) oder verwende die folgenden Befehle:
helm show values groundhog2k/wordpress
helm show values groundhog2k/wordpress | less
```

### Schritt 4.2 Upgrade und resources ändern 

```
cd ~/wordpress-values/prod
nano values.yaml
```

Ergänze die resources:

```yaml
# Resources für WordPress
resources:
  limits:
    memory: 512Mi
  requests:
    memory: 256Mi
    cpu: 100m

# Ingress aktivieren
ingress:
  enabled: true
  className: traefik
  hosts:
    - host: wordpress-<dein-namenskuerzel>.appv1.do.t3isp.de
      paths:
        - path: /
          pathType: Prefix

# WordPress Storage (persistent)
storage:
  requestedSize: 10Gi
  accessModes:
    - ReadWriteOnce

# MariaDB Subchart
mariadb:
  enabled: true
  settings:
    rootPassword: geheim123
  userDatabase:
    name: wordpress
    user: wpuser
    password: wppass123
  storage:
    requestedSize: 8Gi
  resources:
    limits:
      memory: 300Mi
    requests:
      memory: 200Mi
      cpu: 100m
```

```
cd ..
```

```
# Testen 
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.4 --dry-run -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.4 -f prod/values.yaml
```

```
kubectl get pods
kubectl describe pods my-wordpress-0
helm list
helm history my-wordpress
helm get values my-wordpress  
```

## Schritt 4.3 Weiteres Update der Chart - Version

```
# Testen 
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.5 --dry-run -f prod/values.yaml  
```

```
# Real Upgrade
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.5 -f prod/values.yaml
```

```
# Schlägt fehl, weil mit dem apply bestimmte Felder nicht überschrieben dürfen, die geändert wurden im Template
```

### Lösung 

  * Deinstallieren (pvc bleibt erhalten auch beim Deinstallieren -> so macht das helm)
  * Und wieder installieren in der neuen Version 

```
# Frage, ist das pvc noch ?
kubectl get pvc
# Ja ! 
```

```
helm uninstall my-wordpress
kubectl get pvc 
# auch nach der Deinstallation ist der pvc noch da
# Super !! 
```

```
# Real Upgrade
helm upgrade --install my-wordpress groundhog2k/wordpress --reset-values --version 0.14.5 -f prod/values.yaml
```

```
kubectl get pods
```

## Tipp: values aus alter revision anzeigen 

```
# Beispiel: 
helm get values my-wordpress --revision 1
```

### Uninstall 

```
helm uninstall my-wordpress 
# namespace wird nicht gelöscht
# händisch löschen
kubectl delete ns app-<namenskuerzel>
# crd's werden auch nicht gelöscht 
```

## Problem: OutOfMemory (OOM-Killer) if container passes limit in memory 

  * if memory of container is bigger than limit an OOM-Killer will be triggered
  * How to fix: Use memory limit in the application too!
    * PHP memory_limit in WordPress konfigurieren
    * https://techcommunity.microsoft.com/blog/appsonazureblog/unleashing-javascript-applications-a-guide-to-boosting-memory-limits-in-node-js/4080857

## Hinweis: Externe Datenbank verwenden (optional)

Falls du eine externe MariaDB/MySQL verwenden möchtest statt dem integrierten Subchart:

```
nano values.yaml
```

```yaml
mariadb:
  enabled: false

externalDatabase:
  name: wordpress
  user: wpuser
  password: wppass123
  host: my-external-db
```
