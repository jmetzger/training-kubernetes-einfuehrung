# Einfache helm chart erstellen 

## Exercise 

```
cd
mkdir -p my-charts
cd my-charts
helm create simple-chart 
```

```
# Alles Weg was wir nicht brauchen
cd simple-chart
rm values.yaml
cd templates
rm -f *.yaml
rm -fR tests
echo "Ausgabe nach Install" > NOTES.txt
```

```
nano deploy.yaml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 8 # tells deployment to run 8 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.26
        ports:
        - containerPort: 80
```

```
# aus dem templates ordner raus 
cd ..
# aus dem chart raus
cd ..
```

```
# Installieren 
helm -n my-simple-app-<namenskuerzel> upgrade --install my-simple-app simple-chart --create-namespace
kubectl -n my-simple-app-<namenskuerzel> get all 
```
 
## Exercise Phase 2: Um Replicas erweitern 

```
cd simple-chart
nano values.yaml
```

```
deployment:
  replicas: 5
```

```
cd templates
nano deploy.yaml
```

````
# aus der Zeile:
# replicas: 9
# wird ->
  replicas: {{ .Values.deployment.replicas }}
```

```
ä Gehen aus dem Chart raus 
cd ..
cd ..
helm template simple-chart
helm -n my-simple-app-<namenskuerzel> upgrade --install my-simple-app simple-chart --create-namespace
kubectl -n my-simple-app-<namenskuerzel> get pods 
```

```
nano simple-app-values.yaml
```

```
deployment:
  replicas: 2
```

```
helm -n my-simple-app-<namenskuerzel> upgrade --install my-simple-app simple-chart -f simple-app-values.yaml
kubectl -n my-simple-app-<namenskuerzel> get pods
```
