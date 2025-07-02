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
# Schritt 1: repo bekanntmachen 
helm repo add bitnami https://charts.bitnami.com/bitnami
# Schritt 2: Installieen bzw. Upgrade 
helm upgrade --install my-nginx bitnami/nginx --version 19.1.1 -f values.yaml
```
