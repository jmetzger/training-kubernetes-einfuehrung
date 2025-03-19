# NFS 

  * Step 1 + 2 : nur Trainer
  * ab Step 3: Trainees 

## Step 1: Do the same with helm - chart 

```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.11.0
```

## Step 2: Storage Class 

```
cd
mkdir -p manifests
cd manifests
mkdir csi-storage
cd csi-storage 
nano 01-storageclass.yml
```

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.135.0.69
  share: /var/nfs
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

## Step 3: Persistent Volume Claim 

```
cd
mkdir -p manifests
cd manifests
mkdir csi
cd csi
nano 02-pvc.yaml
```

```
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-nfs-dynamic
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
  storageClassName: nfs-csi
```

```
kubectl apply -f .
kubectl get pvc 
```

## Step 4: Pod 

```
nano 03-pod.yaml
```

```
kind: Pod
apiVersion: v1
metadata:
  name: nginx-nfs
spec:
  containers:
    - image: nginx:1.23
      name: nginx-nfs
      command:
        - "/bin/bash"
        - "-c"
        - set -euo pipefail; while true; do echo $(date) >> /mnt/nfs/outfile; sleep 1; done
      volumeMounts:
        - name: persistent-storage
          mountPath: "/mnt/nfs"
          readOnly: false
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: pvc-nfs-dynamic
```

```
kubectl apply -f .
kubectl get pods
```


```
kubectl exec -it nginx-nfs -- bash 
```

## Step 5: Testing

```
cd /mnt/nfs
ls -la
# outfile
tail -f /mnt/nfs/outfile
```

```
CTRL+C
exit
```

## Step 6: Destroy 

```
kubectl delete -f 03-pod.yaml 

## Verify in nfs - trainer !! 
```

## Step 7: Recreate 

```
kubectl apply -f 03-pod.yaml
```

```
kubectl exec -it nginx-nfs -- bash
```

```
# is old data here ? 
head /mnt/nfs/outfile 
#
tail -f /mnt/nfs/outfile
```

```
CTRL + C
exit
```
## Step 8: Cleanup 

```
kubectl delete -f .
```


## Reference:

 * https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/
