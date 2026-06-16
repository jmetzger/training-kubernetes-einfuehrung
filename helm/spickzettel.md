# Spickzettel helm (Wichtigste Befehle) 

## Hilfe 

```
helm help
helm help <command>
helm help upgrade
```


## Alle helm-releases anzeigen 

```
# im eigenen Namespace 
helm list
# in allen Namespaces
helm list -A
# für einen speziellen
helm -n kube-system list 
```

## Helm - Chart installieren 

```
# Empfehlung mit namespace
# Repo hinzufügen für Client 
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-nginx bitnami/nginx --version 19.0.1 --create-namespace --namespace=app-<namenskuerzel>
# besser upgrade --install --reset-values (immer alle Werte wie im aktuellen Installationsbefehl
helm upgrade --install --reset-values my-nginx bitnami/nginx --version 19.0.1 --create-namespace --namespace=app-<namenskuerzel>
```

## Helm - prüfen (nach Installation)

```
helm status my-release
helm get values my-release
helm get manifest my-release
```

## Helm - Suche  

```
# welche Repos sind konfiguriert
helm repo list
helm search repo bitnami
helm search hub
```

## Helm - template 

```
# Rendern des Templates
helm repo add bitnami https://charts.bitnami.com/bitnami
helm template my-nginx bitnami/nginx
helm template bitnami/nginx
```  

