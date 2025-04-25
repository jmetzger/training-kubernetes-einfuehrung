# Daemonset 

## Exercise mit HostNetwork (Teil 1) 


```
cd
mkdir -p manifests
cd manifests
mkdir hostnetwork
cd hostnetwork
```

```
nano 01-hostnetwork.yml
```

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-hostnetwork
spec:
  selector:
    matchLabels:
      app: nginx-hostnetwork
  template:
    metadata:
      labels:
        app: nginx-hostnetwork
    spec:
      hostNetwork: true     # Ganzer Netzwerk-Namespace des Hosts
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80   # Kein hostPort nötig – läuft direkt auf dem Host
        resources:
          limits:
            cpu: "100m"
            memory: "128Mi"

```

```
kubectl apply -f .
kubectl get ds nginx-hostnetwork
kubectl describe ds nginx-hostnetwork
kubectl get pods
```

```
# Externe IP finden
kubectl get nodes -o wide 

# Testen mit curl
# Achtung bei digitalocean sperrt das firewall 
# Port von nginx 
curl http://<node-ip>:80
```

```
# Alternative:
kubectl run -it --rm podtest --image busybox
```

```
# In der busybox
wget -O - <node-ip>:80
```


## Exercise mit HostNetwork (Teil 2) - Umschauen  

```
# Wir suchen uns einen pod raus, z.B. nginx-hostport-t7pxd
kubectl debug -it nginx-hostnetwork-skmrg  --image=busybox
```

```
# in busybox ephemeral container 
ip a
# und direkt connection von nginx prüfen
wget -O - http://localhost:80  
```
