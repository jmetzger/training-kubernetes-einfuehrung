# Exercise Cronjob 

```
cd
mkdir -p manifests
cd manifests
mkdir cronjobs
cd cronjobs
```

```
nano 01-cronjob.yml
```

```
apiVersion: batch/v1
kind: CronJob
metadata:
  name: hello
spec:
  schedule: "*/5 * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: hello
            image: busybox:1.28
            imagePullPolicy: IfNotPresent
            command:
            - /bin/sh
            - -c
            - date; echo Hello from the Kubernetes cluster
          restartPolicy: OnFailure
```

```
kubectl apply -f .
kubectl get cronjobs
kubectl get jobs
kubectl get pods
```
 

