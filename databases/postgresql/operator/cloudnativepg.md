# Cloudnative-pg 

## Vorteile:

  * Unter der Schirmherrschaft der Linux Foundation
  * Alle Komponenten auch für HA sind bereits nativ implentiert 

## Installation über Helm-Chart 

  * Raussuchen aus artifacthub.io

## Wie bauen wir jetzt ein HA-Cluster 

```
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pg-ha
spec:
  instances: 3
  storage:
    size: 10Gi
  postgresql:
    parameters:
      shared_buffers: "256MB"
      max_connections: "100"
  backup:
    barmanObjectStore:
      destinationPath: "s3://pg-backups/"
```

  * eine Instanz ist RW
  * die beiden anderen Instanzen sind ro (das wird über die Service geschlüsselt)

## Mit Synchronisierung zumindest auf eine Replica 

  * Stichwort: minSyncReplicas (damit ist erst erfolgreich geschrieben, wenn das erfüllt ist und dann wir das auch erst an den Client gemeldet

```
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: pg-ha
  namespace: postgres
spec:
  instances: 3

  # Synchrone Replikation – kein Datenverlust bei Failover
  minSyncReplicas: 1
  maxSyncReplicas: 2

  storage:
    size: 10Gi
    storageClass: do-block-storage

  postgresql:
    parameters:
      shared_buffers: "256MB"
      max_connections: "100"
      wal_level: "replica"

  # Pods auf verschiedene Nodes verteilen
  affinity:
    topologyKey: kubernetes.io/hostname
```
  

## Was ist das für eine Lösung 

  * Active / Standby 
