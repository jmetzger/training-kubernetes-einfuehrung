# Verbindung zu pod testen 

## Situation 

```
Managed Cluster und ich kann nicht auf einzelne Nodes per ssh zugreifen
```

## Behelf: Eigenen Pod starten mit busybox 

```
kubectl run podtest --rm -ti --image busybox -- /bin/sh
```
