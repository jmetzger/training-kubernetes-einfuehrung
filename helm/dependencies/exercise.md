# Using Dependencies 

## Prepare: Create folder structure 

```
cd 
mkdir -p my-charts 
helm create app
cd app
```

## Exercise 1: Create chart with Dependency 

```
nano Chart.yaml 
```

```
# Add dependencies 
dependencies:
  - name: redis
    version: "0.9.x"
    repository: "oci://registry-1.docker.io/cloudpirates"
```

```
# Das 1. Mal - dann wird Chart.lock angelegt 
helm dependency update
ls -la Chart.lock
ls -la charts/
```

```
rm -fR charts
helm dependency build
```

```
helm dependency --help 
## what is the difference 
```

```
helm template .
```

## Exercise 2: Create chart with condition 

### Schritt 1 

```
nano Chart.yaml
```

```
# change dependency block
# adding condition 
dependencies:
  - name: redis
    version: "0.9.x"
    repository: "oci://registry-1.docker.io/cloudpirates"
    condition: redis.enabled
```

```
nano values.yaml
```

```
# unten anfügen 
redis:
  enabled: false
```

```
helm template .
# oder wenn die release app in namespace installiert wurde 
helm -n app-<euer-name> template app . 
```

### Schritt 2

```
# values-file anlegen
cd
mkdir -p helm-values
cd helm-values
mkdir app
cd app
```

```
nano values.yaml
```

```
redis:
  enabled: true
```

```
cd
cd my-charts
helm template app -f ../helm-values/app/values.yaml
helm template app -f ../helm-values/app/values.yaml | grep kind -A 2
```

### Schritt 3: Installation update 

```
helm -n app-<euer-name> upgrade --reset-values --install app app -f ../helm-values/app/values.yaml
```

```
helm -n app-<euer-name> status app
```
