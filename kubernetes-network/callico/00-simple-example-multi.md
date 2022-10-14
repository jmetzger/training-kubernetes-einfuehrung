# Simple Example Calico 

## Um was geht es ? 

  * Wir wollen Firewall-Regeln mit Kubernetes machen (NetworkPolicy) 
  * Firewall in Kubernetes -> Network Policies 


## Gruppe mit eigenem cluster 

```
<tln> = nix 
z.B. 
policy-demo<tln> => policy-demo
```


## Gruppe mit einem einzigen Cluster

```
<tln> = Teilnehmernummer  
z.B. 
policy-demo<tln> => policy-demo1
```



## Walkthrough 

```
# Schritt 1:
kubectl create ns policy-demo<tln>
kubectl create deployment --namespace=policy-demo<tln> nginx --image=nginx
kubectl expose --namespace=policy-demo<tln> deployment nginx --port=80
# lassen einen 2. pod laufen mit dem auf den nginx zugreifen 
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox -- /bin/sh
```
```
# innerhalb der shell 
wget -q nginx -O -
```

## Schritt 2: Policy festlegen, dass kein Ingress Traffic erlaubt ist 

```
cd 
cd manifests 
mkdir network
cd network 
nano 01-policy.yml 
```

```
# Deny Regel 
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
  namespace: policy-demo<tln>
spec:
  podSelector:
    matchLabels: {}
```


```
kubectl apply -f 01-policy.yml 
```

```
# lassen einen 2. pod laufen mit dem auf den nginx zugreifen 
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox -- /bin/sh
```

```
# innerhalb der shell 
# kein Zugriff möglich
wget -O - nginx 
```


## Schritt 3: Zugriff erlauben von pods mit dem Label run=access 

```
cd 
cd manifests 
cd network
nano 02-allow.yml 
```

```
# Schritt 3: 
# 02-allow.yml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
  namespace: policy-demo<tln>
spec:
  podSelector:
    matchLabels:
      app: nginx
  ingress:
    - from:
      - podSelector:
          matchLabels:
            run: access
```


```
kubectl apply -f 02-allow.yml 
```

```
# lassen einen 2. pod laufen mit dem auf den nginx zugreifen 
# pod hat durch run -> access automatisch das label run:access zugewiesen 
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox -- /bin/sh
```

```
# innerhalb der shell 
wget -q nginx -O -
```

``` 
kubectl run --namespace=policy-demo<tln> no-access --rm -ti --image busybox -- /bin/sh
```

```
# in der shell  
wget -q nginx -O -
```

```

kubectl delete ns policy-demo<tln>

```


## Ref:

  * https://projectcalico.docs.tigera.io/security/tutorials/kubernetes-policy-basic
  * https://kubernetes.io/docs/concepts/services-networking/network-policies/
  * https://docs.cilium.io/en/latest/security/policy/language/#http
