# Run as unpriliged user 

## Schritt 1:

```
cd
mkdir -p manifests
cd manifests
mkdir -p unpriv
cd unpriv
```

```
nano pod.yaml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: nginx-unprivileged
spec:
  securityContext:
    runAsUser: 1000  # Container läuft mit UID 1000 statt root
  containers:
    - name: nginx
      image: nginx:1.25
      ports:
        - containerPort: 80
```

```
kubectl apply -f .
kubectl get pods
```


## Schritt 2: Debuggen 

```
# CrashLoopBackoff 
kubectl get pods nginx-unprivileged 
kubectl describe pods nginx-unprivileged
```

```
# permission denied identifiziert 
kubectl logs nginx-unprivileged
```

## Schritt 3: Lösung anderes image nehmen 

```
# in pod.yaml
# Zeile image: nginx:1.25
# in -> image: nginxinc/nginx-unprivileged:1.25
# ändern
```

```
kubectl apply -f .
kubectl get pods
```
