# Exercise Job 

```
cd
mkdir -p manifests
cd manifests
mkdir jobs
cd jobs
```

```
nano 01-job.yml
```

```
apiVersion: batch/v1
kind: Job
metadata:
  name: pi
spec:
  template:
    spec:
      containers:
      - name: pi
        image: perl:5.34.0
        command: ["perl",  "-Mbignum=bpi", "-wle", "print bpi(2000)"]
      restartPolicy: Never
  backoffLimit: 4
```

```
kubectl apply -f .
kubectl get jobs && kubectl get pods
```
