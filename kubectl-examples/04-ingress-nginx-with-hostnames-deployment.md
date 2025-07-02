# Ingress Nginx mit Hostnamen/Domains

## Step 1: Walkthrough 

```
cd 
cd manifests
mkdir abi 
cd abi
```

```
nano apple-deploy.yml 
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apple-app
  labels:
    app: apple
spec:
  replicas: 1
  selector:
    matchLabels:
      app: apple
  template:
    metadata:
      labels:
        app: apple
    spec:
      containers:
        - name: apple-app
          image: hashicorp/http-echo
          args:
            - "-text=apple-<euer-name>"
```

```
nano apple-svc.yaml
```


```
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
kubectl apply -f .
```

```
nano banana-deploy.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: banana-app
  labels:
    app: banana
spec:
  replicas: 1
  selector:
    matchLabels:
      app: banana
  template:
    metadata:
      labels:
        app: banana
    spec:
      containers:
        - name: apple-app
          image: hashicorp/http-echo
          args:
            - "-text=banana-<euer-name>"
```

```
nano banana-svc.yaml
```

```
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
kubectl apply -f .
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
  - host: "<euername>.lab.t3isp.de"
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

## Step 4: Find the problem 

### Fix 4.1: Fehler: no matches kind "Ingress" in version "extensions/v1beta1"

```
# Gibt es diese Landkarte überhaupt
kubectl api-versions
# auf welcher Landkarte/Gruppe befindet sich Ingress jetzt 
kubectl explain ingress 
# -> jetzt auf networing.k8s.io/v1 

```

```
nano ingress.yaml
```

```
# auf apiVersion: extensions/v1beta1
# wird -> networking.k8s.io/v1
```

```
kubectl apply -f .
```

## Fix 4.2: Bad Request unkown field ServiceName / ServicePort 


```
# was geht für die Property backend 
kubectl explain ingress.spec.rules.http.paths.backend
# und was geht für service
kubectl explain ingress.spec.rules.http.paths.backend.service
```

```
nano ingress.yml
```

```
# Wir ersetzen 
# serviceName: apple-service 
# durch:
# service: 
#   name: apple-service 

# das gleiche für banana 
```

```
kubectl apply -f . 
```


## Fix 4.3. BadRequest unknown field servicePort

```
# was geht für die Property backend 
kubectl explain ingress.spec.rules.http.paths.backend
# und was geht für service
kubectl explain ingress.spec.rules.http.paths.backend.service.port
# number 
kubectl explain ingress.spec.rules.http.paths.backend.service.port
```

```
# neue Variante sieht so aus
backend:
  service:
    name: apple-service
    port:
      number: 80
# das gleich für banana-service
```

```
kubectl apply -f .
```


## Fix 4.4. 


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
  - host: "app12.lab1.t3isp.de"
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
