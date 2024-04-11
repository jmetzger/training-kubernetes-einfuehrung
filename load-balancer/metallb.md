# Setup

## Installation 

 * Refs: https://metallb.universe.tf/installation/

## Step 1: Installation: 

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.9/config/manifests/metallb-native.yaml
```

## Step 2: Konfiguration 

```
mkdir -p manifests
cd manifests 
mkdir metallb 
vi 01-pool.yaml 
```

```
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
```

```
vi 02-l2.yaml

```

```
# now we need to propagate
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

## References 

  * https://microk8s.io/docs/addon-metallb
  * https://metallb.universe.tf/
  * Calico Issues: https://metallb.universe.tf/configuration/calico/
  
## Documentation 

  * [Set IP to specific interface and node](https://metallb.universe.tf/configuration/_advanced_l2_configuration/)
