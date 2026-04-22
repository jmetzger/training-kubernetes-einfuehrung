# kubectl aufsetzen und konfigurieren

## config einrichten 

```
cd
mkdir -p .kube
cd .kube
cp /tmp/config config
ls -la
# Alternative: nano config befüllen 
# das bekommt ihr aus Eurem Cluster Management Tool 
```

```
kubectl cluster-info
```

## Arbeitsbereich konfigurieren 

```
NS=jochen # diesen app 
```

```
kubectl create ns $NS
kubectl get ns
kubectl config set-context --current --namespace $NS
kubectl get pods
```


```
# Beispiel 
# kubectl create ns jochen
# kubectl get ns
# kubectl config set-context --current --namespace jochen
# kubectl get pods
```
