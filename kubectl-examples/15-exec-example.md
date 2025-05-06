# Example Example with kubectl exec and nginx 

```
kubectl run my-nginx --image=nginx:1.23 
```

```
kubectl exec my-nginx -- ls -la
kubectl exec -it my-nginx -- bash 
kubectl exec -it my-nginx -- sh 
```

```
# in der shell 
cat /etc/os-release
cd /var/log/nginx 
ls -la 
exit 
```

```
# Logs ausgeben 
kubectl logs my-nginx 
```
