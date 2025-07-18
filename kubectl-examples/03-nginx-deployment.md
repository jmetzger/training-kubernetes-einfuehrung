# Example Deployment nginx 

## Prepare 

```
cd
mkdir -p manifests 
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
  replicas: 8 # tells deployment to run 8 pods matching the template
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

## Explore 

```
kubectl get all
```

## Optional: Change image - Version 

```
nano nginx-deployment.yml 
```

```
# Version 1:
# Ändern des images von nginx:1.22 in nginx:1.23
# danach 
kubectl apply -f . && watch kubectl get pods 
```


```
# Version 2: 

# Ändern des images von nginx:1.22 in nginx:1.23
# danach 
kubectl apply -f .
kubectl get all 
kubectl get pods -w


```

