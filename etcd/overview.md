# etcd 

## Wieviele ? 

  * Ungerade Zahl an etcd - Nodes (3,5,7 max. 7)
  * Ausreichend in der Regel 3
  * Wenn man möchte, dass 2 ausfallen können dann 5

## Besonderheiten bei der Nutzung der etc. 

  * Schnelle Platte, idealerweise ssd .
  * Begrenzung des Key->Values Stores auf 2,1 GB (standardmäßig)

## Besonderheiten multi-data-center Setup 

  * Ursprünglich nicht dafür entwickelt.
  * Sowohl ungerade Zahl an etcd-Nodes als auch ungerade Zahl an Rechenzentren.
  * Ideal ist ein RTT (round trip time) von 10 ms / (maximal 100ms / 1.5 => ca. 66,6 ms)

## etcd 

  * Tuning: https://etcd.io/docs/v3.4/tuning/
  * Maintenance: https://etcd.io/docs/v3.5/op-guide/maintenance/

