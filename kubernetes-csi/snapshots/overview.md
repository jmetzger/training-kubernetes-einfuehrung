# Snaphots Overview 

## Overview 

  * https://kubernetes.io/docs/concepts/storage/volume-snapshots/

## Prerequisite Example 

  * Create pod as mentioned in: [Here](/kubernetes-csi/nfs-exercise.md)

## Example - Walktrough 

  * https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/deploy/example/snapshot

### Step 1: Create SnaphotClass

```
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-nfs-snapclass
driver: nfs.csi.k8s.io
deletionPolicy: Delete
```

### Step 2: create volume snapshot 

```
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: test-nfs-snapshot
spec:
  volumeSnapshotClassName: csi-nfs-snapclass
  source:
    persistentVolumeClaimName: pvc-nfs-dynamic
```

### Step 3: Restore from snapshot 

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-snapshot-restored
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-csi
  dataSource:
    name: test-nfs-snapshot
    kind: VolumeSnapshot
    apiGroup: snapshot.storage.k8s.io
```
