# Metrics-Server installieren und verwenden

## Schritt 1: Trainer installs metrics-server

```
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm upgrade --install metrics-server metrics-server/metrics-server --namespace=metrics --create-namespace
# Check it pods are running 
kubectl -n metrics get pods
```

## Schritt 2: Use it 

```
kubectl run nginx-data --image=nginx:1.27
# how much does it use ? 
kubectl top pods nginx-data 
```
