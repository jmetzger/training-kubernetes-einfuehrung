# kubectl aufsetzen und konfigurieren

## config einrichten 

```
cd
mkdir .kube
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
kubectl create ns jochen
kubectl get ns
kubectl config set-context --current --namespace jochen
kubectl get pods
```
