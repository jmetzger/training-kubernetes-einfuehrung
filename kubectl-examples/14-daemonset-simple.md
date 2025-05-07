# Daemonset (einfacher Variante)

## Exercise mit HostPort

```
cd
mkdir -p manifests
cd manifests
mkdir ds
```

```
nano 01-ds.yml
```

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-ds
spec:
  selector:
    matchLabels:
      app: nginx-ds
  template:
    metadata:
      labels:
        app: nginx-ds
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
```       

```
kubectl apply -f .
kubectl get ds nginx-ds
kubectl describe ds nginx-ds
kubectl get pods
```
