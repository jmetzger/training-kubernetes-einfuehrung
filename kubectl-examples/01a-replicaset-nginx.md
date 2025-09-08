# Replicaset

## Walkthrough Erstellen 

```
cd
mkdir -p manifests
cd manifests 
mkdir 02-rs
cd 02-rs 
nano rs.yml 
```

```
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replica-set
spec:
  replicas: 5
  selector:
    matchLabels:
      tier: frontend
  template:
    metadata:
      name: template-nginx-replica-set
      labels:
        tier: frontend
    spec:
      containers:
        - name: nginx
          image: nginx:1.23
          ports:
             - containerPort: 80
             

```

```
kubectl apply -f .
kubectl get all
# name anpassen
kubectl describe pod/nginx-replica-set-lpkbs
```

## Walthrough Skalieren

```
nano rs.yml
```

```
# Ändern 
# replicas: 5
# -> ändern in
# replicas: 8
```

```
kubectl apply -f .
kubectl get pods
```
