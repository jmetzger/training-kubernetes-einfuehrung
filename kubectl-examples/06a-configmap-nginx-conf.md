# Konfiguration von Nginx mit einer configmap (conf anpassen) 

## Schritt 1: configmap 

```
cd 
mkdir -p manifests
cd manifests
mkdir nginx-conf
cd nginx-conf
nano 01-configmap.yml 
```

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }
    http {
      server {
        listen 80;
        location / {
          return 200 "Hello from ConfigMap!\n";
          add_header Content-Type text/plain;
        }
        location /health {
          return 200 "OK";
        }
      }
    }
```

```
kubectl apply -f .
kubectl describe cm  nginx-config
kubectl get cm
kubectl get cm nginx-config -o yaml
```


## Schritt 2: Pod 
```
nano 02-pod.yml
```

```
apiVersion: v1
kind: Pod
metadata:
  name: custom-nginx
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    volumeMounts:
    - name: nginx-config
      mountPath: /etc/nginx/nginx.conf
      subPath: nginx.conf
  volumes:
  - name: nginx-config
    configMap:
      name: nginx-config
```
```
kubectl apply -f .
kubectl get pods 
kubectl exec -it custom-nginx -- sh
```

```
cd /etc/nginx
cat nginx.conf
exit
```

## Schritt 3: busybox connection 

```
# wir brauchen die pod-ip 
kubectl get pods custom-nginx 
kubectl run -it --rm podtest --image=busybox
```

```
# in der shell
wget -O - <ip-von-oben-aus-schritt-3>
```

```
exit
```


