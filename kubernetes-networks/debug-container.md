# Debug Container / Debug Node 

##  Walkthrough  Debug Container 

```
kubectl run ephemeral-demo --image=registry.k8s.io/pause:3.1 --restart=Never
kubectl exec -it ephemeral-demo -- sh

kubectl debug -it ephemeral-demo --image=ubuntu --target=ephemeral-demo

```

## Walkthrough Debug Node 

```
kubectl get nodes 
kubectl debug node/mynode -it --image=ubuntu
```



## Reference 

  * https://kubernetes.io/docs/tasks/debug/debug-application/debug-running-pod/#ephemeral-container
