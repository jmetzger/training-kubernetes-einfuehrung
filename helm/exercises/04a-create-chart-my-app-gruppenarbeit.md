# Chart my-app erstellen (Gruppenarbeit) 

## Chart erstellen 

```
cd 
mkdir my-charts
cd my-charts
```

```
helm create my-app
``` 

## Install helm - chart 

```
# Variante 1:
helm -n my-app-<namenskuerzel> install meine-app my-app --create-namespace 
```

```
# Variante 2:
cd my-app
helm -n my-app-<namenskuerzel> install meine-app . --create-namespace 
```

```
helm -n my-app-<namenskuerzel> status meine-app 
kubectl -n my-app-<namenskuerzel> get all
kubectl -n my-app-<namenskuerzel> get pods 
```
