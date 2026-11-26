# NFS 

  * Step 1 + 2 : nur Trainer
  * ab Step 3: Trainees

## Requirements:

  * Ein NFS-Server oder eine Storage mit NFS muss im Netz zur Verfügung stehen. 
  * Die IP des NFS-Servers findest du im Training in der Datei `~/nfs-server-ip.txt`

## Step 1: Do the same with helm - chart 

```
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version 4.13.4 --reset-values 
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
  server: 10.135.0.14
  share: /var/nfs
reclaimPolicy: Retain
volumeBindingMode: Immediate
```

```
kubectl apply -f .
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
#
kubectl get pv 
```

## Step 4: Pod 

```
nano 03-pod.yaml
```

```
apiVersion: v1
kind: Pod
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
kubectl describe pods nginx-nfs 
```

## Step 5: Testing

```
kubectl exec -it nginx-nfs -- bash 
```

```
cd /mnt/nfs
ls -la
# outfile
head /mnt/nfs/outfile 
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


## Teil 2: Vorhandenes Share wiederverwenden (statisches PV)

  * In Teil 1 legt der Treiber für jeden PVC ein neues Unterverzeichnis (`pvc-<uid>`) an.
  * Hier binden wir gezielt ein **bestehendes Share** mit festem Namen ein: `share-tln1`, `share-tln2` usw.
  * So kommt ein neuer PVC (auch nach dem Löschen) wieder an dieselben Daten.

### Vorbereitung: nur Trainer (auf dem NFS-Server)

  * Bei statischen PVs legt der Treiber das Verzeichnis **nicht** an. Es muss vorher existieren.

```
for i in $(seq 1 20); do mkdir -p /var/nfs/share-tln$i; done
```

### Step 1: Variablen setzen 

  * Nur die erste Zeile anpassen (deine Teilnehmernummer)
  * Neues Terminal ? Dann diesen Block erneut ausführen.

```
NAME=tln1
```

```
NFS_SERVER=$(cat ~/nfs-server-ip.txt)
echo "$NAME $NFS_SERVER"
mkdir -p ~/manifests/csi-share
cd ~/manifests/csi-share
```

### Step 2: PersistentVolume 

```
cat <<EOF > 01-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-share-${NAME}
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: ""
  csi:
    driver: nfs.csi.k8s.io
    # muss je Volume im Cluster eindeutig sein
    volumeHandle: share-${NAME}
    volumeAttributes:
      server: ${NFS_SERVER}
      share: /var/nfs/share-${NAME}
EOF
```

```
cat 01-pv.yaml
kubectl apply -f 01-pv.yaml
# STATUS: Available
kubectl get pv pv-share-${NAME}
```

### Step 3: PersistentVolumeClaim 

```
cat <<EOF > 02-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-share-${NAME}
spec:
  # "" = keine StorageClass, also keine dynamische Provisionierung
  storageClassName: ""
  # genau dieses PV nehmen
  volumeName: pv-share-${NAME}
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
EOF
```

```
kubectl apply -f 02-pvc.yaml
# STATUS: Bound
kubectl get pvc pvc-share-${NAME}
```

### Step 4: Pod 

  * `\$` im Here-Document: Die Variable wird erst im Container ausgewertet, nicht beim Erstellen der Datei.

```
cat <<EOF > 03-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-share-${NAME}
spec:
  containers:
    - name: nginx
      image: nginx:1.23
      command:
        - "/bin/bash"
        - "-c"
        - echo "start \$(date)" >> /mnt/share/starts.txt; exec nginx -g 'daemon off;'
      volumeMounts:
        - name: share
          mountPath: /mnt/share
  volumes:
    - name: share
      persistentVolumeClaim:
        claimName: pvc-share-${NAME}
EOF
```

```
kubectl apply -f 03-pod.yaml
kubectl wait --for=condition=Ready pod/nginx-share-${NAME} --timeout=120s
kubectl exec nginx-share-${NAME} -- cat /mnt/share/starts.txt
```

### Step 5: Pod und PVC löschen 

  * Erst den Pod, dann den PVC. Solange ein Pod den PVC nutzt, bleibt der PVC im Status `Terminating`.

```
kubectl delete -f 03-pod.yaml
kubectl delete -f 02-pvc.yaml
# STATUS: Released - das PV ist noch da, die Daten auch
kubectl get pv pv-share-${NAME}
```

### Step 6: PVC neu anlegen -> bleibt Pending 

```
kubectl apply -f 02-pvc.yaml
# STATUS: Pending
kubectl get pvc pvc-share-${NAME}
```

  * Das PV merkt sich den alten PVC (`spec.claimRef`, inkl. dessen UID). Der neue PVC hat eine andere UID.

```
kubectl get pv pv-share-${NAME} -o jsonpath='{.spec.claimRef}{"\n"}'
```

### Step 7: PV wieder freigeben 

```
kubectl patch pv pv-share-${NAME} --type=json -p='[{"op":"remove","path":"/spec/claimRef"}]'
# kurz warten: STATUS Bound
kubectl get pv pv-share-${NAME}
kubectl get pvc pvc-share-${NAME}
```

### Step 8: Sind die alten Daten noch da ? 

```
kubectl apply -f 03-pod.yaml
kubectl wait --for=condition=Ready pod/nginx-share-${NAME} --timeout=120s
# zwei Zeilen: erster und zweiter Pod
kubectl exec nginx-share-${NAME} -- cat /mnt/share/starts.txt
```

### Step 9: Cleanup 

```
kubectl delete -f 03-pod.yaml
kubectl delete -f 02-pvc.yaml
kubectl delete -f 01-pv.yaml
```

  * Die Dateien auf dem NFS-Server bleiben trotzdem erhalten. Wenn du Step 2 bis 4 erneut ausführst, sind sie wieder da.

## PVC gelöscht: Was bleibt, was ist weg ?

  * Entscheidend ist die `reclaimPolicy` (StorageClass bzw. `persistentVolumeReclaimPolicy` im PV).

| Aktion | Retain | Delete (dynamisch erzeugtes PV) |
|---|---|---|
| Pod löschen | PVC, PV, Daten bleiben | PVC, PV, Daten bleiben |
| PVC löschen: PV | bleibt (`Released`) | wird gelöscht |
| PVC löschen: Daten | bleiben | werden gelöscht (Unterverzeichnis auf dem NFS-Server) |
| Neuer PVC mit gleichem Namen | neues, leeres Volume (dynamisch) bzw. `Pending` (statisch, bis `claimRef` entfernt ist) | neues, leeres Volume |

  * Statisches PV mit `Delete`: In unserem Test (csi-driver-nfs 4.13.4) verschwand das PV, die Daten blieben, weil der Treiber den frei gewählten `volumeHandle` keinem Verzeichnis zuordnen kann. Darauf nicht verlassen: Wer Daten behalten will, nimmt `Retain`.
  * Merke: Der Pod hat mit dem Löschen der Daten nichts zu tun. Es zählt, was mit dem **PVC** passiert.
  * Die StorageClass `nfs-csi` aus Teil 1 hat `Retain`. Ohne Angabe ist der Default einer StorageClass `Delete`.
  * Die `reclaimPolicy` eines vorhandenen PV kann man nachträglich ändern:

```
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

## Reference:

 * https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/
