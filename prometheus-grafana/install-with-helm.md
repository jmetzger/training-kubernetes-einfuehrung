# Prometheus with Grafana (Install with helm)

  * using the kube-prometheus-stack (recommended !: includes important metrics)

## Step 1: Prepare values-file  

```
cd
mkdir -p manifests 
cd manifests 
mkdir -p monitoring 
cd monitoring 
```

```
vi values.yml 
```

```
fullnameOverride: prometheus

alertmanager:
  fullnameOverride: alertmanager

grafana:
  fullnameOverride: grafana

kube-state-metrics:
  fullnameOverride: kube-state-metrics

prometheus-node-exporter:
  fullnameOverride: node-exporter
```

## Step 2: Install with helm 

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack -f values.yml --namespace monitoring --create-namespace --version 61.3.1
```

## Step 3: Connect to prometheus from the outside world 

### Step 3.1: Start proxy to connect (to on Linux Client)

```
# this is shown in the helm information 
helm -n monitoring get notes prometheus

# Get pod that runs prometheus 
kubectl -n monitoring get service 
kubectl -n monitoring port-forward svc/prometheus-prometheus 9090 &

```

### Step 3.2: Start a tunnel in (from) your local-system to the server 

```
ssh -L 9090:localhost:9090 tln1@164.92.129.7
```

### Step 3.3: Open prometheus in your local browser 

```
# in browser
http://localhost:9090 
```

## Step 4: Connect to the grafana from the outside world 

### Step 4.1: Start proxy to connect 

```
# Do the port forwarding 
# Adjust your pods here
kubectl -n monitoring get pods | grep grafana 
kubectl -n monitoring port-forward grafana-56b45d8bd9-bp899 3000 &
```

### Step 4.2: Start a tunnel in (from) your local-system to the server 

```
ssh -L 3000:localhost:3000 tln1@164.92.129.7
```






## References:

  * https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
  * https://artifacthub.io/packages/helm/prometheus-community/prometheus

  
