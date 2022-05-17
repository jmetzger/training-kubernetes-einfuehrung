# Kubernetes Dashboard 

## Setup / Walkthrough 


```
# Auf Node 1:
microk8s enable dashboard 

# Wenn rbac aktiviert ist, einen Nutzer mit Berechtigung einrichten 


```

```
# Auf Client proxy starten
kubectl proxy 

# Wenn Client, nicht Dein eigener Rechner ist, dann einen Tunnel von Deinem eigenen Rechner zum Client aufbauen  
ssh -L localhost:8001:127.0.0.1:8001 tln1@138.68.92.49

# In Deinem Browser auf Deinem Rechern folgende URL öffnen 
http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/

# Jetzt kannst Du Dich einloggen - verwenden das Token 
```
