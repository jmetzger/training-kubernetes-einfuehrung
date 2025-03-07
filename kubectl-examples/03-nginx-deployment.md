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

## Optional: Change Replicas 

  * from 8 to 12

```
nano nginx-deployment.yml 
```

```
# Ändern der replicas  von 8 auf 12 
# danach
kubectl get all 
kubectl apply -f .
kubectl get all 
kubectl get pods -w

```


## New Version 

```
nano nginx-deployment.yml 
```

```
# Ändern des images von nginx:1.22 in nginx:1.23
# danach 
kubectl apply -f .
kubectl get all 
kubectl get pods -w

```

