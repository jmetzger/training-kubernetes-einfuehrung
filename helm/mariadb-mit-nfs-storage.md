# mariadb mit NFS-Storage 

## Prerequisites 

  * NFS-Server ist bereits aufgesetzt
  * und als StorageClass nfs-csi eingerichtet (kubectl get storageclasses)

## Step 1: Walkthrough (Iteration 1: Does not work - because password missing) 

```
cd
mkdir -p manifests
cd manifests
mkdir mariadb-nfs
cd mariadb-nfs
```

```
nano values.yaml
```

```
global:
   defaultStorageClass: "nfs-csi"

architecture: replication 

foo: so
````

```
helm repo add bitnami https://charts.bitnami.com/bitnami
```

```
helm install mariadb bitnami/mariadb --version 20.4.0 -f values.yaml
```

```
# Fragen wir, hat das geklappt ?
helm list
# Alle releases in allen namespaces 
helm list -A
```

```
# Laufen wirklich alle pods 
kubectl get pods
kubectl get pvc 
```

## Step 2: Walkthrough Again 

```
# Change values.yaml
nano values.yaml
```

```
global:
   defaultStorageClass: "nfs-csi"

architecture: replication 

auth:
  user: "user"
  rootPassword: "newRootPassword123"
  password: "newUserPassword123"
  replicationPassword: "newReplicationPassword123"

````

```
helm upgrade --install mariadb bitnami/mariadb --version 20.4.0 -f values.yaml
```
