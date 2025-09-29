# Verbindung zu pod testen 

## Situation 

```
Managed Cluster und ich kann nicht auf einzelne Nodes per ssh zugreifen
```

## Was wollen wir testen (auf der Verbindungsebene) ?

<img width="900" height="343" alt="image" src="https://github.com/user-attachments/assets/937221ca-20ff-4b1f-926c-cee1f5923f60" />


## Behelf: Eigenen Pod starten mit busybox 

```
# der einfachste Weg
kubectl run podtest --rm -it --image busybox 
```

```
# Alternative 
kubectl run podtest --rm -it --image busybox -- /bin/sh
```



## Example test connection 

```
# wget befehl zum Kopieren
ping -c4 10.244.0.99
wget -O - http://10.244.0.99
```

```
# -O -> Output (grosses O (buchstabe)) 
kubectl run podtest --rm -ti --image busybox -- /bin/sh
/ # wget -O - http://10.244.0.99
/ # exit 
```
