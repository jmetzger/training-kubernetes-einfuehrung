# Volumes with NFS (Share per Student)

## Create new server and install nfs-server

```
# on Ubuntu 20.04LTS
apt install nfs-kernel-server 
systemctl status nfs-server 

vi /etc/exports 
# adjust ip's of kubernetes master and nodes 
# kmaster
/var/nfs/ 192.168.56.101(rw,sync,no_root_squash,no_subtree_check)
# knode1
/var/nfs/ 192.168.56.103(rw,sync,no_root_squash,no_subtree_check)
# knode 2
/var/nfs/ 192.168.56.105(rw,sync,no_root_squash,no_subtree_check)

exportfs -av 
```

## On all nodes (needed for production) 

```
# 
apt install nfs-common 

```

## On all nodes (only for testing)

```
### Please do this on all servers (if you have access by ssh)
## find out, if connection to nfs works ! 

# for testing 
mkdir /mnt/nfs 
# 192.168.56.106 is our nfs-server 
mount -t nfs 192.168.56.106:/var/nfs /mnt/nfs 
ls -la /mnt/nfs
umount /mnt/nfs
```

## Setup PersistentVolume and PersistentVolumeClaim in cluster

```
# mkdir -p nfs; cd nfs
# vi 01-pv.yml 
# Important user  
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
  persistentVolumeReclaimPolicy:
    # retain even if pods terminate
    Retain
  nfs:
    # NFS server's definition
    path: /var/nfs/tln<nr>/nginx
    server: 192.168.56.106
    readOnly: false
  storageClassName: ""

```

```
kubectl apply -f 01-pv.yml 
```

```
# vi 02-pvs.yml 
# now we want to claim space
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pv-nfs-claim-tln<nr>
spec:
  storageClassName: ""
  volumeName: pv-nfs-tln<nr>
  accessModes:
  - ReadWriteMany
  resources:
     requests:
       storage: 1Gi
```


```
kubectl apply -f 02-pvs.yml
```

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
          claimName: pv-nfs-claim-tln1


```

```
kubectl apply -f 03-deploy.yml 

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

# connect to the container and add index.html - data 
kubectl exec -it deploy/nginx-deployment -- bash 
# in container
echo "hello dear friend" > /usr/share/nginx/html/index.html 
exit 

# now try to connect 
kubectl get svc 

# connect with ip and port
kubectl exec -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>:<port> # port -> > 30000
# exit

# now destroy deployment 
kubectl delete -f 03-deploy.yml 

# Try again - no connection 
kubectl exec -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>:<port> # port -> > 30000
# exit 


# now start deployment again 
kubectl apply -f 03-deploy.yml 

# and try connection again  
kubectl exec -it --rm curly --image=curlimages/curl -- /bin/sh 
# curl http://<cluster-ip>:<port> # port -> > 30000
# exit 
```



