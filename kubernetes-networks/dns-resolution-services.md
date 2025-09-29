# DNS Resolution of services 

## Exercise 

```
kubectl run podtest --rm -ti --image busybox
```

## Example with svc-nginx 

```
# in sh
wget -O - http://svc-nginx
wget -O - http://svc-nginx.jochen
wget -O - http://svc-nginx.jochen.svc
wget -O - http://svc-nginx.jochen.svc.cluster.local
```

## How to find the FQDN (Full qualified domain name) 

```
# in busybox (clusterIP)
### Schritt 1: Service-IP ausfindig machen
wget -O - http://svc-nginx
# z.B. 10.109.24.227 

### Schritt 2: nslookup mit dieser Service-IP
nslookup 10.109.24.227
# Ausgabe 
# name = svc-nginx.jochen.svc.cluster.local
```
