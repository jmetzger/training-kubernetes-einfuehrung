# Start pod without capabilities 

## Walkthrough 

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
