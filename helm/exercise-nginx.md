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
helm get all
helm get values
helm get manifest
```


## Part 2: Set Service to NodePort 

```
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
helm upgrade --install my-nginx bitnami/nginx --version 17.3.3 -f values.yaml 
kubectl get pods
kubectl get svc 
```

## Part 3: Upgrade auf die neueste Version mit NodePort 


```
helm upgrade --install my-nginx bitnami/nginx --version 19.1.1 -f values.yaml
```

## Part 4: Uninstall nginx 

```
helm uninstall my-nginx 
```
