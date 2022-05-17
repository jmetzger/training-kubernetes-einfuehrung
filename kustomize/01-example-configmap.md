# Kustomize - Example configmap generator 

## Walkthrough 

```
# External source of truth 
# Create a application.properties file
# vi application.properties
USER=letterman
ORG=it

# No use the generator 
# the name need to be kustomization.yaml 
```

```
# kustomization.yaml
configMapGenerator:
- name: example-configmap-1
  files:
  - application.properties
```

```
# See the output 
kubectl kustomize ./ 

# run and apply it 
kubectl apply -k .
# configmap/example-configmap-1-k4dmb9cbmb created

```

## Ref. 

  * https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/
