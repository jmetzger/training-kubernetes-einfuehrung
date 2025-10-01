# Cloud Pirates Charts Fehleranalyse (nginx)

## Test (mit aktuell letzter Version 0.1.10)

```
helm upgrade --install  my-nginx oci://registry-1.docker.io/cloudpirates/nginx --reset-values --version 0.1.10

## wie sehen die logs aus
kubectl logs deployment/my-nginx
```

```
Permission denied port 80
```

### Lauffaehig mit (leider aktuell so nicht in der Doku)

```
cd
mkdir helm-values/nginx 
cd helm-values/nginx
nano values.yaml
```

```
containerPorts:
- name: http
  containerPort: 8080
  protocol: TCP

serverConfig: |
  server {
    listen 0.0.0.0:8080;
    root /usr/share/nginx/html;
    index index.html index.htm;

    location / {
      try_files $uri $uri/ /index.html;
    }
  }
livenessProbe:
  type: httpGet
  path: /
readinessProbe:
  type: httpGet
  path: /
```

```
helm upgrade --install  my-nginx oci://registry-1.docker.io/cloudpirates/nginx --version 0.1.10 --reset-values -f values.yaml
```

```bash
kubectl exec -it deploy/my-nginx -- sh
```
```
# in der shell
id
```

<img width="707" height="65" alt="image" src="https://github.com/user-attachments/assets/b749f30f-843b-43f8-897e-9aa24704a5da" />

```
# pod läuft nicht unter root
# Deshalb funktioniert ein Öffnen des Ports 80 beim Starten nicht
``` 

