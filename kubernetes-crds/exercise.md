# CRD - Exercise 

## Create our own crd 

### Step 1:

```
cd
mkdir -p manifests/crds
cd manifests/crds 
```

```
nano 01-crd.yml
```

```
# vi 01-crd.yaml 
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: crontabs.stable.example.com
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: stable.example.com
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v1
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: crontabs
    # singular name to be used as an alias on the CLI and for display
    singular: crontab
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: CronTab
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - ct
```
```
kubectl apply -f
kubectl api-versions | grep stable
```

### Step 2: create custom object ;o) 

```
nano 03-crontab.yaml
```

```
# vi 03-crontab.yaml 
apiVersion: "stable.example.com/v1"
kind: CronTab
metadata:
  name: my-new-cron-object
spec:
  cronSpec: "* * * * */5"
  image: my-awesome-cron-image
```

```
kubectl apply -f .
kubectl get crontab
kubectl get crontab -o yaml
```

### Step 3: new version + old objects still there ?  

```
# vi 02-crd.yaml 
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  # name must match the spec fields below, and be in the form: <plural>.<group>
  name: crontabs.stable.example.com
spec:
  # group name to use for REST API: /apis/<group>/<version>
  group: stable.example.com
  # list of versions supported by this CustomResourceDefinition
  versions:
    - name: v2
      # Each version can be enabled/disabled by Served flag.
      served: true
      # One and only one version must be marked as the storage version.
      storage: true
      schema:
        openAPIV3Schema:
          type: object
          properties:
            spec:
              type: object
              properties:
                cronSpec:
                  type: string
                image:
                  type: string
                replicas:
                  type: integer
                remark:
                  type: string 
             
  # either Namespaced or Cluster
  scope: Namespaced
  names:
    # plural name to be used in the URL: /apis/<group>/<version>/<plural>
    plural: crontabs
    # singular name to be used as an alias on the CLI and for display
    singular: crontab
    # kind is normally the CamelCased singular type. Your resource manifests use this.
    kind: CronTab
    # shortNames allow shorter string to match your resource on the CLI
    shortNames:
    - ct
```

## Take the patch approach (Try 1) 

```
kubectl patch customresourcedefinitions crontabs.stable.example.com --subresource='status' --type='merge' -p '{"status":{"storedVersions":["v2"]}}'
kubectl replace -f 02-crd.yaml
kubectl get crontab 
```

## Take the good approach (Try 2) 

```
# go back
kubectl patch customresourcedefinitions crontabs.stable.example.com --subresource='status' --type='merge' -p '{"status":{"storedVersions":["v1"]}}'
kubectl replace -f 01-crd.yaml
# now we can see the again 
kubectl get crontab 
```

```
# get the data
# eventually you will have this in your version control anyway 
kubectl get crontab -A -o yaml > all.yaml 
# this also deletes the corresponding data 
kubectl delete -f 01-crd.yaml # v1
kubectl create -f 02-crd.yaml # v2 
# adjust the version before you apply - we have done this here
kubectl apply -f 03-crontab.yaml
```

## Ref:

  * https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/
