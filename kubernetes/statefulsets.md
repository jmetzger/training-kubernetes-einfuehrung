# Statefulsets 

## Why ?

  * stable network identities (always the same name across restarts)  in contrast to deployments

```
Server:    10.0.0.10
Address 1: 10.0.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-0.nginx
Address 1: 10.244.1.6

nslookup web-1.nginx
Server:    10.0.0.10
Address 1: 10.0.0.10 kube-dns.kube-system.svc.cluster.local

Name:      web-1.nginx
Address 1: 10.244.2
```

```
The Pods' ordinals, hostnames, SRV records, and A record names have not changed, but the IP addresses associated with the Pods may have changed.
```




## Features 

  * Scaling Up: Ordered creation on scaling (web 2 till ready then web-3 till ready and so on) 

```
StatefulSet controller created each Pod sequentially 
with respect to its ordinal index, 

and it waited for each Pod's predecessor to be Running and Ready 

before launching the subsequent Pod
```

  * Scaling Down: last created pod is torn down firstly, till finished, then the one before

```
The controller deleted one Pod at a time, 
in reverse order with respect to its ordinal index, 
and it waited for each to be completely shutdown before deleting the next.
```

  * VolumeClaimTemplate (In addition if the pod is scaled the copies will have their own storage)
    * Plus: When you delete it, it gets recreated and claims the same persistentVolumeClaim 

```
volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

   * Update Strategy: RollingUpdate / OnDelete 
   * Feature: Staging an Update with Partitions
     * https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/#staging-an-update
   * Feature: Rolling out a canary 
     * https://kubernetes.io/docs/tutorials/stateful-application/basic-stateful-set/#rolling-out-a-canary
