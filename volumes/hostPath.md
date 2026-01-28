# Nur geeignet für Pode auf der gleichen node 

```
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-example
spec:
  containers:
  - name: myapp
    image: nginx:alpine
    volumeMounts:
    - name: host-logs
      mountPath: /var/log/host
    - name: host-data
      mountPath: /data
  volumes:
  - name: host-logs
    hostPath:
      path: /var/log
      type: Directory
  - name: host-data
    hostPath:
      path: /mnt/data
      type: DirectoryOrCreate
  ```
