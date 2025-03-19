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
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## Step 1: Walkthrough Again 

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
helm upgrade --install mariadb bitnami/mariadb --version 20.4.1 -f values.yaml
```
