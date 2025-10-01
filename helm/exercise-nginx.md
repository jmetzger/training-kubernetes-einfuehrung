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
helm upgrade --install my-nginx beispiel-chart --reset-values -f ../helm-values/beispiel-chart/values.yaml
kubectl get pods
# neue Revision 
helm list
# hier NodePort auslesen 
kubectl get svc my-nginx-beispiel-chart
kubectl get nodes -o wide  
```

```
# Testen
curl http://<ip-aus-nodes>:<nodePort>
# z.B.
curl http://159.223.24.231:32465
```

### Part 4.3 Explore 

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
# für unser chart
cd
cd charts 
helm show values beispiel-chart # latest version 
```

## Part 5 Uninstall nginx 

```
# Achtung keine Deinstallation von CRD's, keine Deinstallation von PVC (Persistent Volume Claims), RBAC
helm uninstall my-nginx 
```
