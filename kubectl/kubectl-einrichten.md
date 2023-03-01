# kubectl aufsetzen und konfigurieren

## config einrichten 

```
cd
mkdir .kube
cd .kube
cp -a /tmp/config config
ls -la
# nano config befüllen 
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
```
