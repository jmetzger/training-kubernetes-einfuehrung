# Sicherstellen, dass Pods auf unterschiedlichen Nodes laufen (für HA)

## Exercise 

```
cd
mkdir -p manifests
cd manifests
mkdir ha-anti
cd ha-anti
```

```
nano deploy.yaml
```


```
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 3
  template: 
    metadata:
      labels:
        app: nginx
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - nginx
            topologyKey: "kubernetes.io/hostname"
      containers:
      - name: nginx
        image: nginx:1.7.9
        ports:
        - containerPort: 80
```

```
kubectl apply -f .
kubectl get pods -o wide -l app=nginx
```
