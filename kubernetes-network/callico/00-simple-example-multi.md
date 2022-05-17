# Simple Example Calico 

## Gruppe mit eigenen Clustern (jede hat sein eigenes Cluser

```
<tln> = nix 
z.B. 
policy-demo<tln> => policy-demo
```

## Walkthrough 

```
# Schritt 1:
kubectl create ns policy-demo<tln>
kubectl create deployment --namespace=policy-demo<tln> nginx --image=nginx
kubectl expose --namespace=policy-demo<tln> deployment nginx --port=80
# lassen einen 2. pod laufen mit dem auf den nginx zugreifen 
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox /bin/sh
```
```
# innerhalb der shell 
wget -q nginx -O -
```


```
# Schritt 2: Policy festlegen, dass kein Ingress-Traffic erlaubt
# in diesem namespace: policy-demo 
# mkdir network; cd network 
# vi 01-policy.yml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: default-deny
  namespace: policy-demo-<tln>
spec:
  podSelector:
    matchLabels: {}
```


```
kubectl apply -f 01-policy.yml 
```

```
# lassen einen 2. pod laufen mit dem auf den nginx zugreifen 
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox /bin/sh
```

```
# innerhalb der shell 
# kein Zugriff möglich
wget -q nginx -O -
```

```
# Schritt 3: Zugriff erlauben von pods mit dem Label run=access 
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
kubectl run --namespace=policy-demo<tln> access --rm -ti --image busybox /bin/sh
```

```
# innerhalb der shell 
wget -q nginx -O -
```

``` 
kubectl run --namespace=policy-demo<tln> no-access --rm -ti --image busybox /bin/sh
```

```
# in der shell  
wget -q nginx -O -
```

```

kubectl delete ns policy-demo 

```


## Ref:

  * https://projectcalico.docs.tigera.io/security/tutorials/kubernetes-policy-basic
