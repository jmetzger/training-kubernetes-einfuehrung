# Debug Container / Debug Node 

## Beispiel 1a: Walkthrough  Debug Container 

```
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never
kubectl exec -it ephemeral-demo -- sh

kubectl debug -it ephemeral-demo --image=ubuntu --target=ephemeral-demo

```

## Beispiel 1b: Walkthrough Debug Container with apple-app 

```
cd
mkdir -p manifests
cd manifests
mkdir debugcontainer
cd debugcontainer
nano apple.yml
```


```
kind: Pod
apiVersion: v1
metadata:
  name: newapple-app
  labels:
    app: apple
spec:
  containers:
    - name: apple-app
      image: hashicorp/http-echo
      args:
        - "-text=apple-jochen"
```

```
kubectl apply -f .
```

```
# does not work
kubectl exec -it newapple-app -- bash
kubectl exec -it newapple-app -- sh
```

```
kubectl debug -it newapple-app --image=ubuntu
```


## Walkthrough Debug Node 

```
kubectl get nodes 
kubectl debug node/mynode -it --image=ubuntu
```



## Reference 

  * https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
