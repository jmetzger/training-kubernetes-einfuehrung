# Kubernetes Tipps Hardening 

## PSA (Pod Security Admission) 

```
Policies defined by namespace.
e.g. not allowed to run container as root.

Will complain/deny when creating such a pod with that container type

```

## Example (seccomp / security context) 

```
A. seccomp - profile
https://github.com/docker/docker/blob/master/profiles/seccomp/default.json

```

```
apiVersion: v1
kind: Pod
metadata:
  name: audit-pod
  labels:
    app: audit-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: profiles/audit.json

  containers:

  - name: test-container
    image: hashicorp/http-echo:0.2.3
    args:
    - "-text=just made some syscalls!"
    securityContext:
      allowPrivilegeEscalation: false

```

## SecurityContext (auf Pod Ebene) 

```
kubectl explain pod.spec.containers.securityContext 

```


## NetworkPolicy 

```
# Firewall Kubernetes 
```


# Grundlagen Security 

## Geschichte 

  * Namespaces sind die Grundlage für Container 
  * LXC - Container 
  
## Grundlagen 
 
  * letztendlich nur ein oder mehreren laufenden Prozesse im Linux - Systeme 
  
## Seit: 1.2.22 Pod Security Admission 

  * 1.2.22 - ALpha - D.h. ist noch nicht aktiviert und muss als Feature Gate aktiviert (Kind)
  * 1.2.23 - Beta -> d.h. aktiviert  

## Vorgefertigte Regelwerke 

  * privileges - keinerlei Einschränkungen 
  * baseline - einige Einschränkungen 
  * restricted - sehr streng 

## Praktisches Beispiel für Version ab 1.2.23 - Problemstellung 

```
# Schritt 1: Namespace anlegen 

# mkdir manifests/security
# cd manifests/security 
# vi 01-ns.yml 

apiVersion: v1
kind: Namespace
metadata:
  name: test-ns<tln>
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted

```

```
kubectl apply -f 01-ns.yml 
```

```
# Schritt 2: Testen mit nginx - pod 
# vi 02-nginx.yml 

apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: test-ns<tln>
spec:
  containers:
    - image: nginx
      name: nginx
      ports:
        - containerPort: 80

```

```
# a lot of warnings will come up 
kubectl apply -f 02-nginx.yml
```

````
# Schritt 3:
# Anpassen der Sicherheitseinstellung (Phase1) im Container 

# vi 02-nginx.yml 

apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: test-ns<tln>
spec:
  containers:
    - image: nginx
      name: nginx
      ports:
        - containerPort: 80
      securityContext:     
        seccompProfile:    
          type: RuntimeDefault
```

```
kubectl delete -f 02-nginx.yml
kubectl apply -f 02_pod.yml
kubectl -n test-ns<tln> get pods 
```

```
# Schritt 4: 
# Weitere Anpassung runAsNotRoot 
# vi 02-nginx.yml 
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: test-ns12
spec:
  containers:
    - image: nginx
      name: nginx
      ports:
        - containerPort: 80
      securityContext:
        seccompProfile:
          type: RuntimeDefault
        runAsNonRoot: true

```

```
# pod kann erstellt werden, wird aber nicht gestartet 
kubectl delete -f 02_pod.yml 
kubectl apply -f 02_pod.yml 
kubectl -n test-ns<tln> get pods
kubectl -n test-ns<tln> describe pods nginx 
```

## Praktisches Beispiel für Version ab 1.2.23 -Lösung - Container als NICHT-Root laufen lassen

  * Wir müssen ein image, dass auch als NICHT-Root kaufen kann 
  * .. oder selbst eines bauen (;o)) 
  o bei nginx ist das bitnami/nginx 
 
```
# vi 03-nginx-bitnami.yml 
apiVersion: v1
kind: Pod
metadata:
  name: bitnami-nginx
  namespace: test-ns12
spec:
  containers:
    - image: bitnami/nginx
      name: bitnami-nginx
      ports:
        - containerPort: 80
      securityContext:
        seccompProfile:
          type: RuntimeDefault
        runAsNonRoot: true
```

```
# und er läuft als nicht root 
kubectl apply -f 03_pod-bitnami.yml 
kubectl -n test-ns<tln> get pods
```
