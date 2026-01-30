# Heap Memory Analyse 

```
4. Heap memory analyse 

# JVM-Beispiel: Direkt im Container
kubectl exec -it <pod> -- jmap -heap <pid>
kubectl exec -it <pod> -- jstat -gc <pid> 1000

# Oder Metriken exportieren
# - JMX Exporter für JVM
# - Prometheus + Grafana für Visualisierung
# - /actuator/metrics (Spring Boot)

# zu viel speicher 
kubectl top pods 

# OOM killer 
kubectl describe po <pod-name>

# Crashed 
# OOMKilled Pods finden
kubectl get pods -A -o json | \
jq '.items[] | select(.status.containerStatuses[].lastState.terminated.reason=="OOMKilled")'

# CPU-Throttling Events
kubectl get events -A --field-selector reason=FailedScheduling

# Pods ohne Limits (gefährlich!)
kubectl get pods -A -o json | \
jq '.items[] | select(.spec.containers[].resources.limits==null)'
```
