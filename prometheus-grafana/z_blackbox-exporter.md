# Setup Blackbox exporter 

## Prerequisites 

  * prometheus setup with helm

## Step 1: Setup

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install my-prometheus-blackbox-exporter prometheus-community/prometheus-blackbox-exporter --version 8.17.0 --namespace monitoring --create-namespace

```

## Step 2: Find SVC 

```
kubectl -n monitoring get svc | grep blackbox
```

```
my-prometheus-blackbox-exporter   ClusterIP   10.245.183.66    <none>        9115/TCP              
```


## Step 3: Test with Curl 

```
kubectl run -it --rm curltest --image=curlimages/curl -- sh 
```

```
# Testen nach google in shell von curl
curl http://my-prometheus-blackbox-exporter.monitoring:9115/probe?target=google.com&module=http_2xx
```

```
# Looking for metric 
probe_http_status_code 200
```

## Step 4: Test apple-service with Curl 

```
# From within curlimages/curl pod 
curl http://my-prometheus-blackbox-exporter.monitoring:9115/probe?target=apple-service.app&module=http_2xx
```


## Step 5: Scrape Config (We want to get all services being labeled example.io/should_be_probed = true

```
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
    - job_name: "blackbox-microservices"
      metrics_path: /probe
      params:
        module: [http_2xx]
      # Autodiscovery through kube-api-server 
      # https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config
      kubernetes_sd_configs:
      - role: service
      relabel_configs:
        # Example relabel to probe only some services that have "example.io/should_be_probed = true" annotation
        - source_labels: [__meta_kubernetes_service_annotation_example_io_should_be_probed]
          action: keep
          regex: true
        - source_labels: [__address__]
          target_label: __param_target
        - target_label: __address__
          replacement:  my-prometheus-blackbox-exporter:9115
        - source_labels: [__param_target]
          target_label: instance
        - action: labelmap
          regex: __meta_kubernetes_service_label_(.+)
        - source_labels: [__meta_kubernetes_namespace]
          target_label: app
        - source_labels: [__meta_kubernetes_service_name]
          target_label: kubernetes_service_name
```

## Step 6: Test with relabeler 

 * https://relabeler.promlabs.com

```


```

## Step 7: Scrapeconfig einbauen 

```
# von kube-prometheus-grafana in values und ugraden 
 helm upgrade prometheus prometheus-community/kube-prometheus-stack -f values.yml --namespace monitoring --create-namespace --version 61.3.1
```

## Step 8: annotation in service einfügen 

```
kind: Service
apiVersion: v1
metadata:
  name: apple-service
  annotations:
    example.io/should_be_probed: "true"

spec:
  selector:
    app: apple
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5678 # Default port for image
```


```
kubectl apply -f service.yml
```

## Step 9: Look into Status -> Discovery Services and wait

  * blackbox services should now appear under blackbox_microservices
  * and not being dropped

## Step 10: Unter http://64.227.125.201:30090/targets?search= gucken

  * .. ob das funktioniert

## Step 11: Hauptseite (status code 200) 

  * Metrik angekommen `?
  * http://64.227.125.201:30090/graph?g0.expr=probe_http_status_code&g0.tab=1&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=1h

## Step 12: pod vom service stoppen

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: apple-deployment
spec:
  selector:
    matchLabels:
      app: apple
  replicas: 8
  template:
    metadata:
      labels:
        app: apple
    spec:
      containers:
      - name: apple-app
        image: hashicorp/http-echo
        args:
        - "-text=apple-<dein-name>"


```

```
kubectl apply -f apple.yml # (deployment)

```

## Step 13: status_code 0


  * Metrik angekommen `?
  * http://64.227.125.201:30090/graph?g0.expr=probe_http_status_code&g0.tab=1&g0.display_mode=lines&g0.show_exemplars=0&g0.range_input=1h
