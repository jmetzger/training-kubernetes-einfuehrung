# k3 installieren 

## Exercise 

```
Schritt 1: windows store ubuntu installieren und ausführen

Siehe: 
https://docs.k3s.io/quick-start

# in den root benutzer wechseln
sudo su - 
# passwort eingeben 

curl -sfL https://get.k3s.io | sh -

systemctl stop k3s
# k3s automatischer start beim booten ausschalten
systemctl disable k3s 
systemctl start k3s

# Verwenden 
kubectl cluster-info 
kubectl get nodes 
```
