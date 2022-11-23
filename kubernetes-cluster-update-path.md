# Kubernetes Cluster Update Path 

```
I. Schritt 1 (Optional aber zu empfehlen): Testsystem mit neuer Version aufsetzen (z.B. mit kind oder direkt in der Cloud)

II. Schritt 2: Manifeste auf den Stand bringen, dass sie mit den 
neuen Api's funktionieren, sprich ApiVersion anheben.

III. Control Plane upgraden. 

Achtung: In dieser Zeit steht die API nicht zur Verfügung.
Die Workloads im Cluster funktionieren nach wievor.

IV. Nodes upgraden wie folgt in 2 Varianten:

Variante 1: Rolling update

Jede Node wird gedrained und die der Workload auf einer neuen Node 
hochgezogen.

Variante 2: Surge Update 

Es werden eine Reihe von weiteren Nodes bereitgestellt, die bereits mit der
neuen Version laufen.

Alle Workloads werden auf den neuen Nodes hochgezogen und wenn diese dort laufen, 
wird auf diese Nodes umgeswitcht. 


https://medium.com/google-cloud/zero-downtime-gke-cluster-node-version-upgrade-and-spec-update-dad917e25b53
```

 

