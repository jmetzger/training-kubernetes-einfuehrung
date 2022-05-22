# Schritt - für - Schritt Debug Ingress 

## 1. Schritt Pods finden, die als Ingress Controller fungieren 

```
# -A alle namespaces 
kubectl get pods -A | grep -i ingress 
# jetzt sollten die pods zu sehen
# Dann logs der Pods anschauen und gucken, ob Anfrage kommt 
# Hier steht auch drin, wo sie hin geht (zu welcher PodIP) 
# microk8s -> namespace ingress 
# Frage: HTTP_STATUS_CODE welcher ? z.B. 404 
kubectl logs -n ingress <controller-ingress-pod> 

```

## 2. Schritt Pods analyieren, die Anfrage bekommen 


```
# Dann den Pod herausfinden, wo die Anfrage hinging 
# anhand der IP 
kubectl get pods -o wide 

# Den entsprechenden pod abfragen bzgl. der Logs
kubectl logs <pod-name-mit-ziel-ip>


```
