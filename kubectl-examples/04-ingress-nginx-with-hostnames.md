# Ingress Nginx mit Hostnamen/Domains

## Step 1: Walkthrough 

```
cd 
cd manifests
mkdir abi 
cd abi
nano apple.yml 
```

```
# apple.yml 
# vi apple.yml 
kind: Pod
apiVersion: v1
metadata:
  name: apple-app
  labels:
    app: apple
spec:
  containers:
    - name: apple-app
      image: hashicorp/http-echo
      args:
        - "-text=apple-<euer-name>"
---

kind: Service
apiVersion: v1
metadata:
  name: apple-service
spec:
  type: ClusterIP
  selector:
    app: apple
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5678 # Default port for image
```

```
kubectl apply -f apple.yml 
```

```
nano banana.yml
```


```
# banana
# vi banana.yml
kind: Pod
apiVersion: v1
metadata:
  name: banana-app
  labels:
    app: banana
spec:
  containers:
    - name: banana-app
      image: hashicorp/http-echo
      args:
        - "-text=banana-<euer-name>"

---

kind: Service
apiVersion: v1
metadata:
  name: banana-service
spec:
  type: ClusterIP
  selector:
    app: banana
  ports:
    - port: 80
      targetPort: 5678 # Default port for image
```

```
kubectl apply -f banana.yml
```

## Step 2: Testing connection by podIP and Service 

```
kubectl get svc
kubectl get pods -o wide
kubectl run podtest --rm -it --image busybox
```

```
/ # wget -O - http://<pod-ip>:5678 
/ # wget -O - http://<cluster-ip>
```

## Step 3: Walkthrough 

```
nano ingress.yml
```

```
# Ingress
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "<euername>.lab1.t3isp.de"
    http:
      paths:
        - path: /apple
          backend:
            serviceName: apple-service
            servicePort: 80
        - path: /banana
          backend:
            serviceName: banana-service
            servicePort: 80
```

```
# ingress 
kubectl apply -f ingress.yml
```

## Reference 

  * https://matthewpalmer.net/kubernetes-app-developer/articles/kubernetes-ingress-guide-nginx-example.html

## Find the problem 


### Schritt 1: api-version ändern

```
# Welche Landkarten gibt es ?
kubectl api-versions
# Auf welcher Landkarte ist Ingress jetzt
kubectl explain ingress
```

<img width="376" height="69" alt="image" src="https://github.com/user-attachments/assets/15111f3d-f82e-4b79-99c4-2670e4332524" />

```
# ingress ändern ingress.yml 
# von
# apiVersion: extensions/v1beta1
# in
apiVersion: networking.k8s.io/v1
```

### Schritt 2: Fehler Eigenschaften beheben 

<img width="947" height="115" alt="image" src="https://github.com/user-attachments/assets/c2f7760e-2853-4f24-b6a1-20bafa779024" />

```
# Problem serviceName beheben
# Was gibt es stattdessen
# -> es gibt service aber keine serviceName 
kubectl explain ingress.spec.rules.http.paths.backend
# -> es gibt service.name 
kubectl explain ingress.spec.rules.http.paths.backend.
```

```
# Korrektur 2x in ingress.yaml: Inkl. servicePort (neu: service.port.number
# vorher
#  backend:
#            serviceName: apple-service
#            servicePort: 80
# jetzt:
  service:
    name: apple-service
    port:
      number: 80
```

```
kubectl apply -f . 
```

### Schritt 3: pathType ergänzen 

<img width="907" height="46" alt="image" src="https://github.com/user-attachments/assets/8da36c28-7737-49ba-a9a0-994a21fd02fb" />


  * Es wird festgelegt wie der Pfad ausgewertet

```
# Wir müssen pathType auf der 1. Unterebene von paths einfügen
# Entweder exact oder prefix 
```

<img width="372" height="124" alt="image" src="https://github.com/user-attachments/assets/615884d5-2335-4dc1-99fd-cc79a224a8b6" />

```
kubectl apply -f .
```

### Schritt 4: Testen aufrufen 

```
curl http://<euername>.lab1.t3isp.de/apple
curl http://<euername>.lab1.t3isp.de/apple/ # Sollte nicht funktioniert
curl http://<euername>.lab1.t3isp.de/banana
curl http://<euername>.lab1.t3isp.de/banana/
curl http://<euername>.lab1.t3isp.de/banana/something
```

```
Das kann man auch so im Browser eingeben
```

## Solution

```
nano ingress.yml
```

```
# in kubernetes 1.22.2 - ingress.yml needs to be modified like so.
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: "<euername>.lab1.t3isp.de"
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service:
              name: apple-service
              port:
                number: 80
        - path: /banana
          pathType: Prefix
          backend:
            service:
              name: banana-service
              port:
                number: 80                
```

```
kubectl apply -f .
kubectl get ingress example-ingress
# mit describe herausfinden, ob er die services gefundet 
kubectl describe ingress example-ingress
```
