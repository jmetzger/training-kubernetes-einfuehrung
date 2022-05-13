# Wie aktiviere ich RBAC für den Kube-Api-Server 

## Generell

```
Es muss das flat --authorization-mode=RBAC für den Start des Kube-Api-Server gesetzt werden

Dies ist bei jedem Installationssystem etwas anders (microk8s, Rancher etc.) 

```

## Wie ist es bei microk8s 

```
Auf einem der Node:

microk8s enable rbac 

ausführen 

Wenn ich ein HA-Cluster (control-planes) eingerichtet habe, ist dies auch auf den anderen Nodes (Control-Planes) aktiv.
```
