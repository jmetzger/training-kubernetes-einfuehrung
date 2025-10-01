# Exercise nginx (eigenes Chart lokal)

## Part 1: Chart erstellen 

```
cd
mkdir -p charts
cd charts
# mit helm neues Chart erstellen
helm create beispiel-chart
``` 

## Part 2: chart installieren 

```
helm upgrade --install my-nginx beispiel-chart
```

## Part 3: funktioniert es ?

```
kubectl get pods
helm list
```

## Part 4: Spezielle Konfiguration 

### Part 4.1: Analyse 

```
# Können wir die replicas und den type server ändern
# Entweder variante 1 ins Chart
less beispiel-chart/values.yaml
# mit hlem bordmitteln
helm show values beispiel-chart | less
```

### Part 4.2. values.yaml  (eigene Knfiguration) erstellen und anwenden 

```
cd
mkdir helm-values
cd helm-values
mkdir beispiel-chart
cd beispiel-chart
nano values.yaml
```

```
# in der Datei values.yaml
replicaCount: 2
service:
  type: NodePort
```

```
cd
cd charts
helm upgrade --install my-nginx beispiel-chart -f ../helm-values/beispiel-chart/values.yaml
kubectl get pods
# neue Revision 
helm list 
```



### Part 1.2. Explore 

```
helm list
helm list -A (über alle namespaces hinweg)
```

```
# Zeige mir alles von der installierten Release 
helm get all my-nginx 
helm get values my-nginx 
helm get manifest my-nginx
```

```
# chart von online
helm show values bitnami/nginx # latest version 
helm show values bitnami/nginx --version 17.3.3

```


## Part 2: Set Service to NodePort 

### Optional: Ein bisschen Linux - Vodoo 

```
# Identify how to set NodePort
# e.g. looking for serve in templates
cd
helm pull bitnami/nginx --untar
cd nginx/templates
# looking for a line with service and next line type
less svc.yaml
# /service -> nächste Eintrag n 
```

```
# less mit q verlassen
q
```

### Werte setzen und upgrade 

```
cd 
mkdir -p helm-values
cd helm-values
mkdir nginx
cd nginx
```

```
nano values.yaml
```

```
service:
  type: NodePort
```

```
kubectl get pods
kubectl get svc
# reset-values empfohlen, weil er dann immer nur das nimmt was explizit in den default - values
# des charts steht
# und zusätzlich von unserem eigenes values file überschrieben wird 
helm upgrade --install my-nginx bitnami/nginx --version 17.3.3 --reset-values -f values.yaml
helm get values my-nginx 
kubectl get pods
kubectl get svc 
```

## Part 3: Upgrade auf die neueste Version mit NodePort 


```
helm upgrade --install my-nginx bitnami/nginx --version 21.1.23 --reset-values -f values.yaml
```

## Part 4: Uninstall nginx 

```
# Achtung keine Deinstallation von CRD's, keine Deinstallation von PVC (Persistent Volume Claims) 
helm uninstall my-nginx 
```
