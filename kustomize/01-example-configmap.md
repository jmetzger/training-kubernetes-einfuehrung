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

# 
kubectl kustomize -f ./ 



```

## Ref. 

  * https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
