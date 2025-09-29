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
nslookup 10.109.6.53
name = svc-nginx.jochen.svc.cluster.local
```
