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
kubectl get pods -l tier=frontend
kubectl get pods --show-labels 
# name anpassen
kubectl describe pod/nginx-replica-set-lpkbs
```

## Pod löschen, was passiert 

```
# kubectl delete po nginx-r<TAB>
# einfach einen pod raussuchen und löschen 
# z.B. 
kubectl delete po nginx-replica-set-xg8jp
```

```
# gucken, welches sind die neuesten ? 
kubectl get pods
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


## Aufräumen des replicasets 

```
kubectl delete -f .
``` 
