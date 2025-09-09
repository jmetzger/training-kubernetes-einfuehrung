# Metallb 

## General 

  * Supports bgp and arp 
  * Divided into controller, speaker 

## Installation Ways  

  * helm 
  * manifests 

## Step 1: install metallb

```
# Just to show some basics 
# Page from metallb says that digitalocean is not really supported well 
# So we will not install the speaker .

helm repo add metallb https://metallb.github.io/metallb 
```

```
# Eventually disabling speaker 
# vi values.yml 

```

```
helm install metallb metallb/metallb --namespace=metallb-system --create-namespace --version 0.14.8
```

## Step 2: addresspool und Propagation-type (config) 

```
cd
mkdir -p manifests
cd manifests
mkdir lb
cd lb
nano 01-addresspool.yml 
```

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  # we will use our external ip here 
  - 134.209.231.154-134.209.231.154
  # both notations are possible 
  - 157.230.113.124/32
```

```
kubectl apply -f .
```

```
nano 02-advertisement.yml
```

```
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

```
kubectl apply -f .
```

## Schritt 4: Test do i get an external ip 

```
nano 03-deploy.yml
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: web-nginx
  replicas: 3
  template:
    metadata:
      labels:
        run: web-nginx
    spec:
      containers:
      - name: cont-nginx
        image: nginx
        ports:
        - containerPort: 80

```


```
nano 04-service.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: svc-nginx
  labels:
    svc: nginx
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: web-nginx
```


```
kubectl apply -f .
kubectl get pods
kubectl get svc
```

```
# auf dem client 
curl http://<ip aus get svc>
```

```
kubectl delete -f 03-deploy.yml 04-service.yml 
```

## Schritt 5: Referenz:

  * https://metallb.io/installation/#installation-with-helm
