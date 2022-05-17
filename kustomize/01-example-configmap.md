# Kustomize - Example configmap generator 

## Walkthrough 

```
# External source of truth 
# Create a application.properties file
# vi application.properties
FOO=Bar

# No use the generator 
# the name need to be kustomization.yaml 
kustomization.yaml
configMapGenerator:
- name: example-configmap-1
  files:
  - application.properties

# See the output 
kubectl kustomize -f ./ 

# run and apply it 
kubectl apply -k .
configmap/example-configmap-1-k4dmb9cbmb created


```

## Ref. 

  * https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
