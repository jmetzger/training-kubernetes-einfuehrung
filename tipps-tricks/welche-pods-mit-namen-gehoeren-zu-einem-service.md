# Pods mit Namen anzeigen, die zu Service gehören 

```
kubectl get svc svc-nginx -o wide
kubectl get pods -l web=my-nginx
```
