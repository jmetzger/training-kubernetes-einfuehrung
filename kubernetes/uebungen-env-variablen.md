# ENV-Variablen in Container hineinbekommen


## Übung 1 - einfach ENV-Variablen direkt setzen  

```
# mkdir envtests
# cd envtest
# vi 01-simple.yml 
apiVersion: v1
kind: Pod
metadata:
  name: print-envs 
spec:
  containers:
  - name: env-print-demo
    image: nginx
    env:
    - name: APP_VERSION
      value: 1.21.1
    - name: APP_FEATURES
      value: "backend,stats,reports"

```

```
kubectl apply -f 01-simple.yml
kubectl get pods 
kubectl exec -it print-envs -- bash 
# env | grep APP  

```


## Übung 2 - ENV-Variablen von Feldern setzen (aus System) 

```
# erstmal falsch 
# und noch ein 2. versteckter Fehler 
# vi 02-feldref.yml 
apiVersion: v1    
kind: Pod    
metadata:    
  name: print-envs-fields   
spec:    
  containers:    
    - name: env-ref-demo    
      image: nginx    
      env:    
      - name: APP_VERSION    
        value: 1.21.1    
      - name: APP_FEATURES                                                                                                                  
        value: "backend,stats,reports"
      - name: APP_POD_IP    
        valueFrom:    
          fieldRef:    
            fieldPath: status.podIP
      - name: APP_POD_STATUS
        valueFrom:              
          fieldRef:   
            fieldPath: status.phase

```

```
kubectl apply -f 02-feldref.yml 
# Fehler, weil es das Objekt schon gibt und es so nicht geupdatet werden kann
# Einfach zum Löschen verwenden
kubectl delete -f 02-feldref.yml
# Nochmal anlegen.
# Wieder fehler s.u. 
kubectl apply -f 02-feldres.yml 
```

```
# Fehler
* spec.containers[0].env[3].valueFrom.fieldRef.fieldPath: Unsupported value: "status.phase": supported values: "metadata.name", "metadata.namespace", "metadata.uid", "spec.nodeName", "spec.serviceAccountName", "status.hostIP", "status.podIP", "status.podIPs"
```

```
# letztes Feld korrigiert 
apiVersion: v1                   
  kind: Pod                        
  metadata:                        
    name: print-envs-fields               
  spec:                            
    containers:                    
    - name: env-ref-demo           
      image: nginx                 
      env:                         
      - name: APP_VERSION          
        value: 1.21.1              
      - name: APP_FEATURES         
        value: "backend,stats,reports"
      - name: APP_POD_IP           
        valueFrom:                 
          fieldRef:                
            fieldPath: status.podIP                                                                                                       
      - name: APP_POD_NODE       
        valueFrom:                 
          fieldRef:                
            fieldPath: spec.nodeName
```

```
kubectl apply -f 02-feldref.yml 
kubectl exec -it print-envs -- bash 
# env | grep APP 
```

## Beispiel mit labels, die ich gesetzt habe:

```
# vi 02-feldref.yml                   
apiVersion: v1                        
kind: Pod                             
metadata:                             
  name: print-envs-fields             
  labels:                             
    app: foo                          
spec:                                 
  containers:                         
    - name: env-ref-demo              
      image: nginx                    
      env:                            
      - name: APP_VERSION             
        value: 1.21.1                 
      - name: APP_FEATURES            
        value: "backend,stats,reports"
      - name: APP_POD_IP              
        valueFrom:                                                                                                                          
          fieldRef:                   
            fieldPath: status.podIP                                                                                                           
      - name: LABEL_APP               
        valueFrom:                    
          fieldRef:                   
            fieldPath: metadata.labels['app']
```


## Übung 3 - ENV Variablen aus configMaps setzen. 

```
# Step 1: ConfigMap
# 03-matchmaker-config.yml 
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  labels:
    app: matchmaker
data:
  MYSQL_DB: matchmaker
  MYSQL_USER: user_matchmaker
  MYSQL_DATA_DIR: /var/lib/mysql
```

```
# Step 2: applying map 
kubectl apply -f 03-matchmaker-config.yml
kubectl get configmap app-config -o yaml
```

```
# Step 3: setup another pod to use it in addition 
# vi 04-matchmaker-app.yml 
apiVersion: v1                   
  kind: Pod                        
  metadata:                        
    name: print-envs-multi               
  spec:                            
    containers:                    
    - name: env-ref-demo           
      image: nginx                 
      env:                         
      - name: APP_VERSION          
        value: 1.21.1              
      - name: APP_FEATURES         
        value: "backend,stats,reports"
      - name: APP_POD_IP           
        valueFrom:                 
          fieldRef:                
            fieldPath: status.podIP                                                                                                       
      - name: APP_POD_NODE       
        valueFrom:                 
          fieldRef:                
            fieldPath: spec.nodeName
      envFrom:
      - configMapRef:
          name: app-config

```


```
kubectl apply -f 04-matchmaker-app.yml 
kubectl exec -it print-envs-multi -- bash 
# env | grep -e MYSQL -e APP_
```


## Übung 4 - ENV Variablen aus Secrets setzen 

```
# Schritt 1: Secret anlegen.
# Diesmal noch nicht encoded - base64 
# vi 06-secret-unencoded.yml 
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
stringData:
    APP_PASSWORD: "s3c3tp@ss"
    APP_EMAIL: "mail@domain.com"
```

```
# Schritt 2: Apply'en und anschauen 
kubectl apply -f 06-secret-unencoded.yml 
# ist zwar encoded, aber last_applied ist im Klartext 
# das könnte ich nur nur umgehen, in dem ich es encoded speichere 
kubectl get secret mysecret -o yaml 
```

```
# Schritt 3: 
# vi 07-print-envs-complete.yml 
apiVersion: v1                   
kind: Pod                        
metadata:                        
  name: print-envs-complete                
spec:                            
  containers:                    
  - name: env-ref-demo           
    image: nginx                 
    env:                         
    - name: APP_VERSION          
      value: 1.21.1              
    - name: APP_FEATURES         
      value: "backend,stats,reports"
    - name: APP_POD_IP           
      valueFrom:                 
        fieldRef:                
          fieldPath: status.podIP                                                                                                       
    - name: APP_POD_NODE       
      valueFrom:                                                                                                                            
        fieldRef:                
          fieldPath: spec.nodeName
    - name: APP_PASSWORD   
      valueFrom:           
        secretKeyRef:      
          name: mysecret   
          key: APP_PASSWORD
    - name: APP_EMAIL      
      valueFrom:           
        secretKeyRef:      
          name: mysecret   
          key: APP_EMAIL   
                           
    envFrom:               
    - configMapRef:        
        name: app-config 


```


```
# Schritt 4: 
kubectl apply -f 07-print-envs-complete.yml 
kubectl exec -it print-envs-complete -- bash 
#env | grep -e APP_ -e MYSQL 
```
