# NFS 

## Step 1: Treiber installieren 

  * https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/docs/install-csi-driver-v4.6.0.md

```
curl -skSL https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/v4.6.0/deploy/install-driver.sh | bash -s v4.6.0 --
```

### Step 2: Storage Class 

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: 10.135.0.7
  share: /var/nfs
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=3
```

### Step 3: Persistent Volume 

```
apiVersion: v1
kind: PersistentVolume
metadata:
  # any PV name
  name: pv-nfs-tln<nr>
  labels:
    volume: nfs-data-volume-tln<nr>
spec:
  capacity:
    # storage size
    storage: 1Gi
  accessModes:
    # ReadWriteMany(RW from multi nodes), ReadWriteOnce(RW from a node), ReadOnlyMany(R from multi nodes)
    - ReadWriteMany
   storageClassName: nfs-csi
     csi:
       driver: nfs.csi.k8s.io
       volumeHandle: <nr>
       volumeAttributes:
          server: 10.135.0.7
          share: /var/nfs/<nr>
```


### Step 4: Persistent Volume Claim 

```
# now we want to claim space
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-nfs-claim-tln1
spec:
  storageClassName: nfs-csi
  volumeName: pv-nfs-tln1
  accessModes:
  - ReadWriteMany
  resources:
     requests:
       storage: 1Gi
```

### Step 5: Deploy 

```
# deployment including mount 
# vi 03-deploy.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 4 # tells deployment to run 4 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
       
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        
        volumeMounts:
          - name: nfsvol
            mountPath: "/usr/share/nginx/html"

      volumes:
      - name: nfsvol
        persistentVolumeClaim:
          claimName: pv-nfs-claim-tln<nr>
```

```
kubectl apply -f 03-deploy.yml 

```

```
nano 04-service.yml
```


```
# now testing it with a service 
# cat 04-service.yml 
apiVersion: v1
kind: Service
metadata:
  name: service-nginx
  labels:
    run: svc-my-nginx
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
  selector:
    app: nginx
```        

```
kubectl apply -f 04-service.yml 
```

### Schritt 4

```
# connect to the container and add index.html - data 
kubectl exec -it deploy/nginx-deployment -- bash 
# in container
echo "hello dear friend" > /usr/share/nginx/html/index.html 
exit 

# get external ip 
kubectl get nodes -o wide 

# now try to connect 
kubectl get svc 

# connect with ip and port
kubectl run -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>
# exit

## oder alternative von extern (Browser) auf Client 
http://<ext-ip>:30154 (Node Port) - ext-ip -> kubectl get nodes -o wide 

# now destroy deployment 
kubectl delete -f 03-deploy.yml 

# Try again - no connection 
kubectl run -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>
# exit 
```

### Schritt 5

```

# now start deployment again 
kubectl apply -f 03-deploy.yml 

# and try connection again  
kubectl run -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>:<port> # port -> > 30000
# exit 
```
