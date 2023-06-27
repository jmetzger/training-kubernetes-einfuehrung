# Example for kustomization with overlay 

## Konzept Overlay 

  * Base + Overlay = Gepatchtes manifest 
  * Sachen patchen.
  * Die werden drübergelegt. 

## Example 1: Walkthrough 

```
cd
mkdir -p manifests
cd manifests
mkdir kexample
cd kexample
```

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
# vi base/kustomization.yml
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
#vi overlays/prod/kustomization.yaml
bases:
- ../../base
patches:
  - path: service-ports.yaml
```

```
# Step 5: create overlay (patch files) 
# vi overlays/prod/service-ports.yaml 
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
kubectl kustomize overlays/prod/

# or apply it directly 
kubectl apply -k overlays/prod/

```

```
# Step 7:
# mkdir -p overlays/dev
# vi overlays/dev/kustomization 
bases:
- ../../base

```

```
# Step 8: 
# statt mit der base zu arbeiten
kubectl kustomize overlays/dev 
```

## Example 2: Advanced Patching with patchesJson6902 (You need to have done example 1 firstly) 

```
####### DEPRECATED ---- use below version 
# Schritt 1:
# Replace overlays/prod/kustomization.yml with the following syntax 
bases:
- ../../base
patchesJson6902:
- target:
    version: v1
    kind: Service
    name: service-app
  path: service-patch.yaml 
```

```
# Schritt 1:
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- ../../base
patches:
- path: service-patch.yaml
  target:
    kind: Service
    name: service-app
    version: v1
```

```
# Schritt 2:
# vi overlays/prod/service-patch.yaml 
- op: remove
  path: /spec/ports
  value: 
  - name: http
    port: 80
- op: add                                                                                                                                   
  path: /spec/ports
  value: 
  - name: https
    port: 443
```

```
# Schritt 3:
kubectl kustomize overlays/prod 

```


## Special Use Case: Change the metadata.name 

```
# Same as Example 2, but patch-file is a bit different 
# vi overlays/prod/service-patch.yaml 
- op: remove          
  path: /spec/ports
  value:              
  - name: http        
    port: 80          
                      
- op: add             
  path: /spec/ports                                                                                                                         
  value:              
  - name: https       
    port: 443         
                      
- op: replace         
  path: /metadata/name
  value: svc-app-test

```

```
kubectl kustomize overlays/prod 
```

## Ref:

  * https://blog.ordix.de/kubernetes-anwendungen-mit-kustomize



