# Kubernetes Network (CNI) 

## Show us 

![pod to pod across nodes](https://www.inovex.de/wp-content/uploads/2020/05/Pod-to-Pod-Networking.png)

## Die Magie des Pause Containers

![Overview Kubernetes Networking](https://www.inovex.de/wp-content/uploads/2020/05/Container-to-Container-Networking_3_neu-400x412.png)


## CNI 

  * Common Network Interface
  * Feste Definition, wie Container mit Netzwerk-Bibliotheken kommunizieren

## Docker - Container oder andere 

  * Container wird hochgefahren -> über CNI -> zieht Netzwerk - IP  hoch. 
  * Container wird runtergahren -> uber CNI -> Netzwerk - IP wird released 

## Welche gibt es ? 

  * Flannel
  * Canal 
  * Calico 
  * Cilium
  
## Flannel

### Overlay - Netzwerk 

  * virtuelles Netzwerk was sich oben drüber und eigentlich auf Netzwerkebene nicht existiert
  * VXLAN 

### Vorteile 

  * Guter einfacher Einstieg 
  * reduziert auf eine Binary flanneld 

### Nachteile 

  * keine Firewall - Policies möglich 
  * keine klassischen Netzwerk-Tools zum Debuggen möglich. 

## Canal 

### General 

  * Auch ein Overlay - Netzwerk 
  * Unterstüzt auch policies 

## Calico

### Generell 

  * klassische Netzwerk (BGP)

### Vorteile gegenüber Flannel 

  * Policy über Kubernetes Object (NetworkPolicies)

### Vorteile 

  * ISTIO integrierbar (Mesh - Netz) 
  * Performance etwas besser als Flannel (weil keine Encapsulation)

### Referenz 
  * https://projectcalico.docs.tigera.io/security/calico-network-policy


## Cilium 

### Generell 

## microk8s Vergleich 

  * https://microk8s.io/compare

```
snap.microk8s.daemon-flanneld
Flannel is a CNI which gives a subnet to each host for use with container runtimes.

Flanneld runs if ha-cluster is not enabled. If ha-cluster is enabled, calico is run instead.

The flannel daemon is started using the arguments in ${SNAP_DATA}/args/flanneld. For more information on the configuration, see the flannel documentation.
```
