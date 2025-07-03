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
helm -n my-app-<namenskuerzel> install my-app-release my-app --create-namespace 
```

```
# Variante 2:
cd my-app
helm -n my-app-<namenskuerzel> install my-app-release . --create-namespace 
```

```
kubectl -n my-app-<namenskuerzel> get all
kubectl -n my-app-<namenskuerzel> get pods 
```
