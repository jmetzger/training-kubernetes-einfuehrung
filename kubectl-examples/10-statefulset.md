# Statefulset 

## Schritt 1: 

```
cd 
mkdir -p manifests 
cd manifests
mkdir sts
cd sts 

```

```
nano 01-svc.yml
```

```
# vi 01-svc.yml 
# Headless Service - no ClusterIP 
# Just used for name resolution of pods
# web-0.nginx
# web-1.nginx 
# nslookup web-0.nginx
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
```

```
nano 02-sts.yml
``

```
# vi 02-sts.yml 
apiVersion: apps/v1
kind: StatefulSet
metadata:
# name des statefulset wird nachher für den dns-namen verwendet 
  name: web
spec:
  serviceName: "nginx"
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: registry.k8s.io/nginx-slim:0.8
        ports:
        - containerPort: 80
          name: web
```

```
kubectl apply -f .

```


## Schritt 2: Auflösung Namen.

```
kubectl run --rm -it podtester --image=busybox

# web ist der name des statefulsets 
ping web-0.nginx 
ping web-1.nginx 

kubectl delete sts web 
kubectl apply -f .
kubectl run --rm -it podtest --image=busybox 

ping web-0.nginx 

```

## Referenz 

  * https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/
