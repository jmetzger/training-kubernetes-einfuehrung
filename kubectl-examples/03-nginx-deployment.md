# Example Deployment nginx 

## Prepare 

```
cd 
cd manifests 
mkdir 03-deploy 
cd 03-deploy 
nano nginx-deployment.yml 
```

```
# vi nginx-deployment.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 8 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.22
        ports:
        - containerPort: 80
        
```

```
kubectl apply -f . 
```

## New Version 

```
nano nginx-deployment.yml 
```

```
# Ändern des images von nginx:latest in nginx:1.21 
# danach 
kubectl apply -f .
kubectl get all 
```

