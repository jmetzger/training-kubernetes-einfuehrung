# Replicaset

```
cd 
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
```
