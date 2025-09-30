# Service - Examples 

## Warum Services ? 

  * Wenn in einem Deployment bei einem Wechsel des images neue Pods erstellen, erhalten diese neue IP-Adresse
  * Nachteil: Man müsste diese dann in allen Applikation ständig ändern, die auf die Pods zugreifen.
  * Lösung: Wir schalten einen Service davor !

## Hintergrund IP-Wechsel 
 
 <img width="930" height="134" alt="image" src="https://github.com/user-attachments/assets/26c16134-1f2a-4b42-8cca-355099d08604" />

 * Image-Version wurde jetzt in Deployment geändert, Ergebnis:

<img width="939" height="137" alt="image" src="https://github.com/user-attachments/assets/fb5a665b-98a7-445b-8ec7-27f12c2267e1" />


## Example I : Service with ClusterIP 

### Schritt 1: Vorbereitung 

```
cd
mkdir -p manifests
cd manifests
mkdir 04-service 
cd 04-service 
```

### Schritt 2: Deployment erstellen 

```
nano deploy.yml 
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-nginx
spec:
  selector:
    matchLabels:
      web: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        web: my-nginx
    spec:
      containers:
      - name: cont-nginx
        image: nginx
        ports:
        - containerPort: 80
```

```
nano service.yml
```


```
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
spec:
  type: ClusterIP
  ports:
  - port: 80
    protocol: TCP
  selector:
    web: my-nginx      
        
```        

```
kubectl apply -f .
# wie ist die ClusterIP ?  
kubectl get all
kubectl get svc svc-nginx
# Find endpoints / did svc find pods ?
kubectl describe svc svc-nginx 
```

### Schritt 3: Deployment löschen 

```
kubectl delete -f deploy.yml
# Keine endpunkte mehr 
kubectl describe svc svc-nginx
```

 ### Schritt 4: Deployment wieder erstellen 

```
kubectl apply -f .
# Endpunkte wieder da
kubectl describe svc svc-nginx
```


## Example II : Short version 

```
# Wo sind wir ?
# cd; cd manifests/04-service 
```

```
nano service.yml
# in Zeile type: 
# ClusterIP ersetzt durch NodePort 

kubectl apply -f .
# NodePOrt ab 30.000 ausfindig machen
kubectl get svc
```

<img width="793" height="44" alt="image" src="https://github.com/user-attachments/assets/16bf90d4-7c3f-4c8f-9846-2ff5d0e63fcf" />

```
kubectl get nodes -o wide
# im client 
curl http://164.92.193.245:30280
```

## Example II : Service with NodePort (long version)

```
# you will get port opened on every node in the range 30000+
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-nginx
spec:
  selector:
    matchLabels:
      web: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        web: my-nginx
    spec:
      containers:
      - name: cont-nginx
        image: nginx
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
  labels:
    run: svc-my-nginx
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
  selector:
    web: my-nginx
       
```        

## Example III: Service mit LoadBalancer (ExternalIP)

```
nano service.yml
# in Zeile type: 
# NodePort ersetzt durch LoadBalancer  

kubectl apply -f .
kubectl get svc svc-nginx
kubectl describe svc svc-nginx 
kubectl get svc svc-nginx -w 
# spätestens nach 5 Minuten bekommen wir eine externe ip
# z.B. 41.32.44.45

curl http://41.32.44.45 
```


## Example getting a specific ip from loadbalancer (if supported) 

```
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx2
spec:
  type: LoadBalancer
  # this line to get a specific ip if supported
  loadBalancerIP: 10.34.12.34
  ports:
  - port: 80
    protocol: TCP
  selector:
    web: my-nginx
```       



## Ref.

  * https://kubernetes.io/docs/concepts/services-networking/connect-applications-service/
