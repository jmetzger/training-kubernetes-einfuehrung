# Example for kustomization with overlay 

## Walkthrough 

```
# Create the structure 
mkdir kustomize-example1 
cd kustomize-example1 
mkdir base 
mkdir -p overlays/prod 

```

```
# Step 1: base dir with files 
# now create the base kustomization file 
# vi base/kustomization.yaml
resources:
- service.yaml 

# Create the service - file 
# vi base/service.yaml 
kind: Service
apiVersion: v1
metadata:
  name: service-app
spec:
  type: ClusterIP
  selector:
    app: simple-app
  ports:
  - name: http
    port: 80 

```

```
# See how it looks like 
kubectl kustomize ./base

```

```
# Step 2: create overlay (patch files) 
# vi overlays/test/service-ports.yaml 
kind: Service
apiVersion: v1
metadata:
  #Name der zu patchenden Ressource
  name: service-app 
spec:
  # Changed to Nodeport
  type: NodePort
  ports: #Die Porteinstellungen werden überschrieben
  - name: https
    port: 443 

```

```
# Step 3: create the customization file accordingly 
#overlays/test/kustomization.yaml
bases:
- ../../base
patches:
- service-ports.yaml
```

```
kubectl kustomization overlays/test

# or apply it directly 
kubectl apply -k overlays/test/

```


## Ref:

  * https://blog.ordix.de/kubernetes-anwendungen-mit-kustomize



