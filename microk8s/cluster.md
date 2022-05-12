# Create a cluster 

## Walkthrough 

```
# auf master (jeweils für jedes node neu ausführen)
microk8s add-node

# dann auf jeweiligem node vorigen Befehl der ausgegeben wurde ausführen
# Kann mehr als 60 sekunden dauern ! Geduld...Geduld..Geduld 
#z.B. -> ACHTUNG evtl. IP ändern 
microk8s join 10.128.63.86:25000/567a21bdfc9a64738ef4b3286b2b8a69

```

## Auf einem Node addon aktivieren z.B. ingress

```
gucken, ob es auf dem anderen node auch aktiv ist. 
```

## Add Node only as Worker-Node 

```
microk8s join 10.135.0.15:25000/5857843e774c2ebe368e14e8b95bdf80/9bf3ceb70a58 --worker
Contacting cluster at 10.135.0.15

root@n41:~# microk8s status
This MicroK8s deployment is acting as a node in a cluster.
Please use the master node.
```



## Ref:

  * https://microk8s.io/docs/high-availability
