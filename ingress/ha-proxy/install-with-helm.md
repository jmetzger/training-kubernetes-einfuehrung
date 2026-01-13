# Install with helm

```
cd 
mkdir -p helm-values/ingress-haproxy
cd helm-values/ingress-haproxy
```

```
nano values.yaml
```

```
service:
   type: LoadBalancer
```

```
helm repo add haproxytech https://haproxytech.github.io/helm-charts
helm upgrade -n ingress-haproxy --install ingress-haproxy haproxytech/kubernetes-ingress --version 1.47.4 --reset-values -f values.yaml  
```


## Ref:

  * https://artifacthub.io/packages/helm/haproxytech/kubernetes-ingress
