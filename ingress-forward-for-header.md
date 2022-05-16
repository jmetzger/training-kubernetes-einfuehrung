# Forward Header For setzten 

```
# Ingress            
apiVersion: networking.k8s.io/v1
kind: Ingress        
metadata:            
  name: apache-ingress
  annotations:       
    ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Forwarded-For $http_x_forwarded_for";
                     
spec:                
  rules:             
  - http:            
      paths:         
        - path: /project
          pathType: Prefix                                                                                                                  
          backend:
            service:
              name: svc-apache
              port:
                number: 80

```


## Refs:


  * https://stackoverflow.com/questions/62337379/how-to-append-nginx-ip-to-x-forwarded-for-in-kubernetes-nginx-ingress-controller
  * https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#configuration-snippet
