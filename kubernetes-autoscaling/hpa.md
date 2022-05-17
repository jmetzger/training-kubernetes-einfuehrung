# HorizonalPodAutoscaler - Example 

## Aufbau 

```
# Aufbau des Containers 
ROM php:5-apache
COPY index.php /var/www/html/index.php
RUN chmod a+rx index.php
This code defines a simple index.php page that performs some CPU intensive computations, in order to simulate load in your cluster.

<?php
  $x = 0.0001;
  for ($i = 0; $i <= 1000000; $i++) {
    $x += sqrt($x);
  }
  echo "OK!";
?>
```

## Walkthrough 

```
# vi 01-php-apache-deploy.yml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-apache
spec:
  selector:
    matchLabels:
      run: php-apache
  replicas: 1
  template:
    metadata:
      labels:
        run: php-apache
    spec:
      containers:
      - name: php-apache
        image: k8s.gcr.io/hpa-example
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 500m
          requests:
            cpu: 200m
---
apiVersion: v1
kind: Service
metadata:
  name: php-apache
  labels:
    run: php-apache
spec:
  ports:
  - port: 80
  selector:
    run: php-apache


```


```
kubectl apply -f 01-php-apache-deploy.yml 
```


```
# autoscaler erstellen
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
kubectl get hpa 
kubectl get hpa -o yaml 

# Output
##NAME         REFERENCE                     TARGET    MINPODS   MAXPODS   REPLICAS   AGE
## php-apache   Deployment/php-apache/scale   0% / 50%  1         10        1  

```

```
# Last erhöhen 
# Run this in a separate terminal
# so that the load generation continues and you can carry on with the rest of the steps
kubectl run -i --tty load-generator --rm --image=busybox:1.28 --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://php-apache; done"

# type Ctrl+C to end the watch when you're ready
kubectl get hpa php-apache --watch
# Nach ca. 1 Minute geht die Last hoch 

# NAME         REFERENCE                     TARGET      MINPODS   MAXPODS   REPLICAS   AGE
# php-apache   Deployment/php-apache/scale   305% / 50%  1         10        1          3m

# Und etwas später noch mehr 

# NAME         REFERENCE                     TARGET      MINPODS   MAXPODS   REPLICAS   AGE
# php-apache   Deployment/php-apache/scale   305% / 50%  1         10        7  

```

```
# Wie sieht es aus ?
kubectl get deployment php-apache
# You should see the replica count matching the figure from the HorizontalPodAutoscaler

NAME         READY   UP-TO-DATE   AVAILABLE   AGE
php-apache   7/7      7           7           19m
```

## Ref:

  * https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/ 
