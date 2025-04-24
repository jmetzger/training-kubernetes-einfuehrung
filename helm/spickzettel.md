# helm Spickzettel 

## Alle installierten Releases anschauen 

```
# im eigenen Namespaces 
helm list
# in allen Namespaces 
helm list -A
```

## Installieren am besten mit upgraden 


```
# helm install release-name repo/chart --version 1.9.9. -f values.yaml
# z.B.
helm upgrade --install my-nginx bitnami/nginx --version 19.1.1 -f values.yaml
```
