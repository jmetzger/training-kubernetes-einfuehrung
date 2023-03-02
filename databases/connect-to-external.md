# Connect to external database 

## Prerequisites 

  * MariaDB - Server is running on digitalocean in same network as doks (kubernetes) - cluster (10.135.0.x) 
  * DNS-Entry for mariadb-server.t3isp.de -> pointing to private ip: 10.135.0.9

## Variante 1:

### Schritt 1: Service erstellen 

```
cd 
mkdir -p manifests
cd manifests
mkdir 05-external-db 
cd 05-external-db 
nano 01-external-db.yml
```

```
apiVersion: v1
kind: Service
metadata:
  name: dbexternal
spec:
  type: ExternalName
  externalName: mariadb-server.t3isp.de
```

```
kubectl apply -f 01-external-db.yml 
```

### Schritt 2: configmap anlegen oder ergänzen 

```
# Ergänzen 
# unter data zwei weitere Zeile 
## 01-configmap.yml
kind: ConfigMap
apiVersion: v1
metadata:
  name: mariadb-configmap
data:
  # als Wertepaare
  MARIADB_ROOT_PASSWORD: 11abc432
  DB_USER: ext
  DB_PASS: 11dortmund22
```

```
kubectl apply -f 01-configmap.yml  
```


### Schritt 3: Service testen 

```
kubectl run --rm -it ubuntu --image=ubuntu -- bash
```

```
# in container install mariadb-server 
apt update 
apt install -y mariadb-server 
```


## Variante 2:

```
cd 
mkdir -p manifests
cd manifests
mkdir 05-external-db 
cd 05-external-db 
nano 02-external-endpoint.yml
```

