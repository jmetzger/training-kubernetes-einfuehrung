# Run pod with example 

## Example (that does work)

```
# Synopsis (most simplistic example 
# kubectl run NAME --image=IMAGE_EG_FROM_DOCKER
# example
kubectl run nginx --image=nginx 

kubectl get pods 
# on which node does it run ? 
kubectl get pods -o wide 
```

## Example (that does not work) 

```
kubectl run foo2 --image=foo2
# ImageErrPull - Image konnte nicht geladen werden 
kubectl get pods 
# Weitere status - info 
kubectl describe pods foo2 
```

## Ref:

  * https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#run
