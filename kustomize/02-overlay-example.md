# Example for kustomization with overlay 

## Konzept Overlay 

  * Base + Overlay = Gepatchtes manifest 
  * Sachen patchen.
  * Die werden drübergelegt. 

## Example 1: Walkthrough 

```
# Step 1:
# Create the structure 
# kustomize-example1
# L base 
# | - kustomization.yml 
# L overlays 
#.    L dev
#       - kustomization.yml 
#.    L prod 
#.      - kustomization.yml 
mkdir -p kustomize-example1/base 
mkdir -p kustomize-example1/overlays/prod 
cd kustomize-example1 

```

```
# Step 2: base dir with files 
# now create the base kustomization file 
# vi base/kustomization.yaml
resources:
- service.yml 
```

```
# Step 3: Create the service - file 
# vi base/service.yml 
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
# Step 4: create the customization file accordingly 
#vi overlays/dev/kustomization.yaml
bases:
- ../../base
patches:
- service-ports.yaml
```

```
# Step 5: create overlay (patch files) 
# vi overlays/dev/service-ports.yaml 
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
# Step 6:
kubectl kustomization overlays/dev

# or apply it directly 
kubectl apply -k overlays/dev/

```


## Ref:

  * https://blog.ordix.de/kubernetes-anwendungen-mit-kustomize



