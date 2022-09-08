# ENV-Variablen in Container aus Secrets hineinbekommen

## Übung 1 - ENV Variablen aus Secrets setzen 

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
                          


```


```
# Schritt 4: 
kubectl apply -f 07-print-envs-complete.yml 
kubectl exec -it print-envs-complete -- bash 
#env | grep -e APP_ -e MYSQL 
```
