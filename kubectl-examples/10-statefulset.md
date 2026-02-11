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
spec:
  type: ClusterIP
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
```

```
nano 02-sts.yml
```

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
          name: web-nginx
```

```
kubectl apply -f .

```


## Schritt 2: Auflösung Namen.

```
kubectl run --rm -it podtester --image=busybox
```

```
# In der shell
# web ist der name des statefulsets 
ping web-0.nginx 
ping web-1.nginx 
exit
```

```
# web-0 / web-1 
kubectl get pods -o wide 
kubectl get sts web
kubectl delete sts web 
kubectl apply -f .
kubectl run --rm -it podtest --image=busybox 
```

```
# in the shell
# gleicher namer, aber andere IP als beim letzten Ping 
ping web-0.nginx
exit
``` 

```
kubectl describe svc nginx 
```

## Schritt 3: Aufräumen 

```
kubectl delete -f .
```

## Referenz 

  * https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/
