# Start pod without capabilities 

## Walkthrough (nginx)

```
cd
mkdir -p manifests/nocap
cd manifests/nocap
nano nocap-pod-nginx.yaml
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
