# ConfigMap Example (Mariadb) 

## Schritt 1: configmap 

```
cd 
mkdir -p manifests
cd manifests
mkdir cftest 
cd cftest 
nano 01-configmap.yml 
```

```
## 01-configmap.yml
kind: ConfigMap 
apiVersion: v1 
metadata:
  name: mariadb-configmap 
data:
  # als Wertepaare
  MARIADB_ROOT_PASSWORD: 11abc432
```

```
kubectl apply -f .
kubectl describe cm  mariadb-configmap
kubectl get cm
kubectl get cm mariadb-configmap -o yaml
```


## Schritt 2: Deployment 
```
nano 02-deploy.yml
```

```
#deploy.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-deployment
spec:
  selector:
    matchLabels:
      app: mariadb
  replicas: 1 
  template:
    metadata:
      labels:
        app: mariadb
    spec:
      containers:
      - name: mariadb-cont
        image: mariadb:10.11
        envFrom:
        - configMapRef:
            name: mariadb-configmap

```

```
kubectl apply -f .
```

## Schritt 3: Service for mariadb 

```
nano 03-service.yml 
```

```
apiVersion: v1
kind: Service
metadata:
  name: mariadb
spec:
  type: ClusterIP
  ports:
  - port: 3306
    protocol: TCP
  selector:
    app: mariadb
```

```
kubectl apply -f 03-service.yml 
```

## Schritt 4: client aufsetzen 

```
nano 04-client.yml 
```

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mariadb-client
spec:
  selector:
    matchLabels:
      app: ubuntu
  replicas: 1 # tells deployment to run 2 pods matching the template
  template: # create pods using pod definition in this template
    metadata:
      labels:
        app: ubuntu
    spec:
      containers:
      - name: service
        image: ubuntu
        command: [ "/bin/sh" , "-c", "tail -f /dev/null" ]
        envFrom:
        - configMapRef:
            name: mariadb-configmap
```

```
kubectl apply -f 04-client.yml 
```



```
# im client 
kubectl exec -it deploy/mariadb-client -- bash 
apt update; apt install -y mariadb-client iputils-ping
```

## Schritt 5: mysql-zugang von aussen erstellen 

```
kubectl exec -it deploy/mariadb-deployment -- bash
```

```
mysql -uroot -p$MARIADB_ROOT_PASSWORD
```

```
# innerhalb von mysql 
create user ext@'%' identified by '11abc432';
grant all on *.* to ext@'%';

```

## Schritt 6: mysql von client aus testen 

```
kubectl exec -it deploy/mariadb-client -- bash
```

```
mysql -uext -p$MARIADB_ROOT_PASSWORD -h mariadb
```

```
show databases;
```

## Important Sidenode 

  * If configmap changes, deployment does not know
  * So kubectl apply -f deploy.yml will not have any effect
  * to fix, use stakater/reloader: https://github.com/stakater/Reloader

