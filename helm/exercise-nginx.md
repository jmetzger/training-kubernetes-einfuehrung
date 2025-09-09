# Exercise nginx 

## Part 1: Install old version 

```
# https://artifacthub.io/packages/helm/bitnami/nginx/17.3.3
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install my-nginx bitnami/nginx --version 17.3.3
kubectl get pods 
```

```
helm list
helm list -A (über alle namespaces hinweg)
```

```
# Zeige mir alles von der installierten Release 
helm get all my-nginx 
helm get values my-nginx 
helm get manifest my-nginx
```

```
# chart von online
helm show values bitnami/nginx # latest version 
helm show values bitnami/nginx --version 17.3.3

```


## Part 2: Set Service to NodePort 

### Optional: Ein bisschen Linux - Vodoo 

```
# Identify how to set NodePort
# e.g. looking for serve in templates
cd
helm pull bitnami/nginx --untar
cd nginx/templates
# looking for a line with service and next line type
less svc.yaml
# /service -> nächste Eintrag n 
```

```
# less mit q verlassen
q
```

### Werte setzen und upgrade 

```
cd 
mkdir -p helm-values
cd helm-values
mkdir nginx
cd nginx
```

```
nano values.yaml
```

```
service:
  type: NodePort
```

```
kubectl get pods
kubectl get svc 
helm upgrade --install my-nginx bitnami/nginx --version 17.3.3 -f values.yaml
helm get values my-nginx 
kubectl get pods
kubectl get svc 
```

## Part 3: Upgrade auf die neueste Version mit NodePort 


```
helm upgrade --install my-nginx bitnami/nginx --version 21.0.3 -f values.yaml
```

## Part 4: Uninstall nginx 

```
helm uninstall my-nginx 
```
