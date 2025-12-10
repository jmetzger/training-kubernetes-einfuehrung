# Deployment Strategy RollingUpdate 

## Ausgangsituation 

  * replicas auf 8 eingestellt im Deployment
  * änderung auf image, dass es nicht gibt

## Welche Werte spielen hier eine Rolle 

  * deployment.spec.strategy.rollingUpdate.maxUnvailability
  * deployment.spec.strategy.rollingUpdate.maxSurge

## Wie sind die Standardwerte 

  * maxSurge: 25%
  * maxUnavailability: 25% 

<img width="313" height="104" alt="image" src="https://github.com/user-attachments/assets/68499544-9693-41ab-9a12-a3d52681d47a" />

## Ablauf. RollingUpdate 

### Runde 1: Rolling Update legt los 

  * Ausgangszustand: 8 pods laufen 
  * Herausfinden, wieviel Pods im alten Replicaset sofort terminiert werden (maxUnavailability)
    * Beispiel: 8 Replicas (25% Unavailility) = 2 Pods -> dürfen sofort terminiert werdeb
  * Herausfinden, weviele Pods im neuen Replicaset dazu gestartet werden dürfenvon 
    * Insgesamt dürfen replicas: 8 + 25% gestartet werden, d.h. gesamt 10
     * Aktuell laufen 8, also noch 2
   
### Ende von Runde 1:

  * 6 Pods im alten Replicaset
  * 2 Pods im neuen Replicaset

### Runde 1: Nächste Rune 

  * Ausgangszustand: 6 Pods laufen (von 8 replicas)
  * Wieviel dürfen gestoppt werden im alten Replicaset (replicas 8, davon 25% -> 2)
    * Also insgesamt müssen im 6 laufen
    * Es können keinen weiteren terminiert werden
  * Wieviel dürfen im neuen Replicaset jetzt noch gestartet werden
    * Insgesamt dürfen replicas: 8 + 25% gestartet werden, d.h. gesamt 10
    * Insgesamt laufen im alten Replicaset 6 und im neuen Replicaset 2, also dürfen noch 2 gestartet werden
   
## Referenz:

  * https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/

```
strategy.rollingUpdate.maxUnavailability:
- scaled down to .... pods immediately when the rolling update
```


