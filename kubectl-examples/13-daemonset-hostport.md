# Daemonset 

## Variante mit HostPort 

  * Übung: tln1 -> 8001
  * ....   tln8 -> 8008

## Exercise mit HostPort (Teil 1) 


```
cd
mkdir -p manifests
cd manifests
mkdir host
cd host
```

```
nano 01-hostport.yml
```

```
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: nginx-hostport
spec:
  selector:
    matchLabels:
      app: nginx-hostport
  template:
    metadata:
      labels:
        app: nginx-hostport
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
          hostPort: 800x   # Achtung Port ersetzen durch eigenen (s.o.)
        resources:
          limits:
            cpu: "100m"
            memory: "128Mi"
```

```
kubectl apply -f .
kubectl get ds nginx-hostport
kubectl describe ds nginx-hostport
kubectl get pods
```

```
# Externe IP finden
kubectl get nodes -o wide 

# Testen mit curl
# Achtung bei digitalocean sperrt das firewall 
curl http://<node-ip>:<euer-teilnehmer-port-s-o>
```

```
# Alternative:
kubectl run -it --rm podtest --image busybox
```

```
# In der busybox
wget -O - <node-ip>:<dein-port>
```


## Exercise mit HostPort (Teil 2) - Umschauen  

```
# Wir suchen uns einen pod raus, z.B. nginx-hostport-t7pxd
kubectl debug -it nginx-hostport-t7pxd --image=busybox
```

```
# in busybox ephemeral container 
ip a
# und direkt connection von nginx prüfen
wget -O - http://localhost:80  
```
