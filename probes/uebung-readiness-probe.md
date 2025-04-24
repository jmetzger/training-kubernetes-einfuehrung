# Uebung Readiness probe 

## Exercise 

```
cd
mkdir -p manifests
cd manifests
mkdir readiness
cd readiness
```

```
nano deploy.yaml 
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-readiness
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-readiness
  template:
    metadata:
      labels:
        app: nginx-readiness
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        readinessProbe:
          exec:
            command: ["cat", "/tmp/ready"]
          initialDelaySeconds: 2
          periodSeconds: 5
        lifecycle:
          postStart:
            exec:
              command: ["sh", "-c", "sleep 30 && touch /tmp/ready"]
```

```
kubectl apply -f .
watch kubectl get pods -l app=nginx-readiness
```

```
kubectl describe pod -l app=nginx-readiness
```


## Optional: do it by hand 

```
# er nimmt den ersten, den er findet 
kubectl exec nginx-readiness-<hash>-<id> -- rm /tmp/ready
# ist nach kurzer Zeit nicht mehr ready 
watch kubectl get pods -l app=nginx-readiness 
```

```
# er nimmt den ersten, den er findet 
kubectl exec nginx-readiness-<hash>-<id> -- touch /tmp/ready
# ist nach kurzer Zeit wieder ready 
watch kubectl get pods -l app=nginx-readiness 
```
