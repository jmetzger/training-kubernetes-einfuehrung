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
helm upgrade --install mariadb bitnami/mariadb --version 20.4.1 -f values.yaml
```

## Step 3: Testing 

```
mariadb -uroot -pnewRootPassword123 
show master status;
create schema isgus;
exit 
exit


kubectl exec -it mariadb-secondary-0 -- bash 
mariadb -uroot -pnewRootPassword123 
show slave status \G
show schemas;
exit 
exit 
```
