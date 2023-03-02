# Connect to external database 

## Prerequisites 

  * MariaDB - Server is running in digialocean in same network as doks - cluster (10.135.0.x) 
  * DNS-Entry for mariadb-server.t3isp.de -> pointing to private ip: 10.135.0.x 

## Variante 1:

```
cd 
mkdir -p manifests
cd manifests
mkdir 05-external-db 
cd 05-external-db 
nano 01-external-name.yml
```


```
kubectl apply -f 01-external-name.yml 
```

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

