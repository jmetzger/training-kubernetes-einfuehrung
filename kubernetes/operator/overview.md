# Kubernetes Operator Overview 

## Overview 

```
o Possibility to extend functionality (new resource/object)
o Mainly to add new controllers to automate things
o Operator will control states
o Makes it easier to configure things.
  e.g. a crd prometheus could create a prometheus server, which consists of 
  of different building blocks (Deployment, Service a.s.o)
```

## How to see CRD's 

```
kubectl get crd 
# Cilium, if present on the system 
kubectl api-resources | grep cil 
```

