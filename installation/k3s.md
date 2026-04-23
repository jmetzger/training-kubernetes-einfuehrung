# k3 installieren 

## Exercise 

```
Schritt 1: windows store ubuntu installieren und ausführen

Schritt 2: Installation von k3s

Siehe: 
https://docs.k3s.io/quick-start

# in den root benutzer wechseln
sudo su - 
# passwort eingeben 

curl -sfL https://get.k3s.io | sh -

# ca. 2 Minuten warten
# Läuft es ?
systemctl status k3s
# evtl. noch die config-datei kopieren, falls kubectl cluster-info nicht funktioniert
mkdir -p ~/.kube; cp -a /etc/rancher/k3s/k3s.yaml ~/.kube/config
kubectl cluster-info
```

### Erster Test 

```
kubectl run nginx --image=nginx:1.27
kubectl get pods
kubectl get nodes -o wide 
```

### Abschalten wenn nicht verwendet 

```
systemctl stop k3s
# k3s automatischer start beim booten ausschalten
systemctl disable k3s 

# Wenn ihr ihn verwendet wollt
systemctl start k3s
```
