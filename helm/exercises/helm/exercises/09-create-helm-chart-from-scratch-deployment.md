# Create helm chart from scratch with Deployment object 

  * Really simple version to start 

## Step 1: Create sample chart 

```
cd
mkdir -p my-charts
cd my-charts
helm create app 
cd app
```

## Step 2: Cleanup 

```
cd templates
rm -fR tests
rm -fR *.yaml
echo "meine app ist ausgerollt" > NOTES.txt
cd ..
rm values.yaml
# leere datei wird erzeugt 
touch values.yaml 
```

## Step 3: Create Deployment manifest 

```
nano templates/deployment.yaml
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
        image: nginxinc/nginx-unprivileged:1.22
        ports:
        - containerPort: 8080
```        

## Step 4: Testen des Charts 

```
helm template .
helm lint .
# Akzeptiert der API das so, wie ich es ihm schicke 
helm -n app-<namenskuerzel> install app . --dry-run  
helm -n app-<namenskuerzel> upgrade --install app . --create-namespace
kubectl -n app-<namenskuerzel> get all
helm -n app-<namenskuerzel> list
helm -n app-<namenskuerzel> status app 
```


