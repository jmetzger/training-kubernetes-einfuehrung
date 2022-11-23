# Istio 

## Schaubild 

![istio Schaubild](https://user-images.githubusercontent.com/1933318/203541631-b70465aa-f1a1-404b-9e0c-eb0fbd2b0c52.png
)

## Istio 

```
# Visualization 
# with kiali (included in istio) 
https://istio.io/latest/docs/tasks/observability/kiali/kiali-graph.png

# Example 
# https://istio.io/latest/docs/examples/bookinfo/
The sidecars are injected in all pods within the namespace by labeling the namespace like so:
kubectl label namespace default istio-injection=enabled

# Gateway (like Ingress in vanilla Kubernetes) 
kubectl label namespace default istio-injection=enabled
```

## istio tls 

 * https://istio.io/latest/docs/ops/configuration/traffic-management/tls-configuration/


## istio - the next generation without sidecar 

  * https://istio.io/latest/blog/2022/introducing-ambient-mesh/
