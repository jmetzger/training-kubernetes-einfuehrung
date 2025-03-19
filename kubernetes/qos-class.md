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

## Wie werden die Pods evicted 

  * Das wird in der folgenden Reihenfolge gemacht: Zu erst alle BestEffort, dann burstable und zum Schluss Guaranteed

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
kubectl describe po qos-demo 
```

## Risiko Guaranteed


 * Limit: CPU: Diese wird maximal zur Verfügung gestellt
 * Limit: Memory: Wenn die Anwendung das Limit überschreitet, greift der OOM-Killer (Out of Memory Killer)
 * Wenn Limit Memory: Dann auch dafür sorgen, dass das laufende Programme selbst auch eine Speichergrenze
   * Java-Programm ohne Speichergrenze oder zu hoher Speichergrenze 


## Burstable 


* At least one Container in the Pod has a memory or CPU request or limit


```
pods/qos/qos-pod-2.yaml
Copy pods/qos/qos-pod-2.yaml to clipboard
apiVersion: v1
kind: Pod
metadata:
  name: qos-demo-2
  namespace: qos-example
spec:
  containers:
  - name: qos-demo-2-ctr
    image: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
```


## BestEffort

  * gar keine Limits und Requests gesetzt (bitte nicht machen)

