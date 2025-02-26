# Quality of Service Class 

## Die Class wird auf Basis der Limits und Requests der Container vergeben

```
Request: Definiert wieviel ein Container mindestens braucht (CPU,memory)
Limit: Definiert, was ein Container maximal braucht.

in spec.containers.resources 
kubectl explain pod.spec.containers.resources

```

## Art der Typen: 

  * Guaranteed
  * Burstable
  * BestEffort 

## Guaranteed 

```
Type: Guaranteed:
https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed

set when limit equals request
(request: das braucht er,
limit: das braucht er maximal) 

Garantied ist die höchste Stufe und diese werden bei fehlenden Ressourcen 
als letztes "evicted"
```

## Guaranteed Exercise 

```
cd
mkdir -p manifests
cd manifests
mkdir qos
cd qos
nano 01-pod.yaml
```


```
apiVersion: v1

kind: Pod
metadata:
  name: qos-demo
spec:
  containers:
  - name: qos-demo-ctr
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "700m"

      requests:
        memory: "200Mi"
        cpu: "700m"
```

```
kubectl apply -f .
```

