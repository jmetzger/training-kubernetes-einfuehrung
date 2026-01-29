# Upgrade Prozess 

## Starten mit Control-Nodes 

  * Warum ? Diese dürfen eine Major neuer sein als die Worker Node

```
# in diesem Fall ist Cluster - Version 1.32 
# 1. GPG-Key herunterladen
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1.33.gpg

# 2. Repo mit Key-Referenz hinzufügen
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-1.33.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
```

```
# Alle verfügbaren Major - Versionen anzeigen
apt-cache madison kubeadm
```

```
kubeadm upgrade plan
kubeadm upgrade apply 1.33.7
```

## Danach die Worker Nodes nacheinander 


```
# Node drainen z.b k8s-w1
kubectl drain k8s-w1 --ignore-daemonsets 
```

```
# in diesem Fall ist Cluster - Version 1.32 
# 1. GPG-Key herunterladen
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.33/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-1.33.gpg

# 2. Repo mit Key-Referenz hinzufügen
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-1.33.gpg] https://pkgs.k8s.io/core:/stable:/v1.33/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt update
```

```
# Alle verfügbaren Major - Versionen anzeigen
apt-cache madison kubeadm
```

```
kubeadm upgrade plan
kubeadm upgrade apply 1.33.7
```
