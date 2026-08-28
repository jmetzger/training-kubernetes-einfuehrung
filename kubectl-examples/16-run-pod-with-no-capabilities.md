# Start pod without capabilities 

## Walkthrough (nginx)

```
cd
mkdir -p manifests/nocap
cd manifests/nocap
nano nocap-pod-nginx.yaml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: nocap-nginx 
spec:
  containers:
    - name: web
      image: nginx 
      securityContext:
        capabilities:
          drop:
          - all
```

```
kubectl apply -f . 
kubectl get pods
```
### Lösung capibility setzen (achtung kein CAP davor 

```
apiVersion: v1
kind: Pod
metadata:
  name: nocap-nginx
spec:
  containers:
    - name: web
      image: nginx
      securityContext:
        capabilities:
          drop:
          - all
          add:
          - CHOWN
```

```
kubectl delete -f .
kubectl apply -f .
```

## Walkthrough  (nginxinc/nginx-unprivileges) 

```
cd
mkdir -p manifests/nocap
cd manifests/nocap
nano nocap-pod.yaml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: nocap-nginx 
spec:
  containers:
    - name: web
      image: nginxinc/nginx-unprivileged:1.25 
      securityContext:
        capabilities:
          drop:
          - all
```

```
kubectl apply -f . 
kubectl get pods
```
