# Verbindung zu pod testen 

## Situation 

```
Managed Cluster und ich kann nicht auf einzelne Nodes per ssh zugreifen
```

## Behelf: Eigenen Pod starten mit busybox 

```
kubectl run podtest --rm -it --image busybox -- /bin/sh
```

## Example test connection 

```
# wget befehl zum Kopieren
wget -O - http://10.244.0.99
```

```
# -O -> Output (grosses O (buchstabe)) 
kubectl run podtest --rm -ti --image busybox -- /bin/sh
/ # wget -O - http://10.244.0.99
/ # exit 
```
