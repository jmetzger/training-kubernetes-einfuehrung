# https - mit letsencrypt in ingress 

## Prerequisites 

  * abi-projekt muss existieren

## Trainer: Schritt 1: cert-manager installieren 

```
helm repo add jetstack https://charts.jetstack.io
helm upgrade --install cert-manager jetstack/cert-manager \
--namespace cert-manager --create-namespace \
--version v1.19.2 \
--set crds.enabled=true \
--reset-values
```

  * Ref: https://artifacthub.io/packages/helm/cert-manager/cert-manager

## Trainer: Schritt 2: Create ClusterIssuer (gets certificates from Letsencrypt)

```
cd
mkdir -p manifests/cert-manager
cd manifests/cert-manager
nano cluster-issuer.yaml
```



```
# cluster-issuer.yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    # Email-Adresse ändern - example.com ist nicht erlaubt 
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: traefik
```

```
kubectl apply -f .
# Should be True 
kubectl get clusterissuer 
```


## Schritt 3: Ingress-Objekt mit TLS erstellen 

```
cd
cd manifests/abi
```

```
nano ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - <dein-name>.app.do.t3isp.de
    secretName: example-tls

  rules:
  - host: "<dein-name>.app.do.t3isp.de"
    http:
      paths:
        - path: /apple
          pathType: Prefix
          backend:
            service:
              name: apple-service
              port:
                number: 80
        - path: /banana
          pathType: Exact
          backend:
            service:
              name: banana-service
              port:
                number: 80
```

```
kubectl apply -f .
```

 * Interessent, der cert-manager erstellt kurz ein Ingress - Objekt

<img width="1057" height="172" alt="image" src="https://github.com/user-attachments/assets/54dce6f5-9d53-4ce4-ac79-dcfe095f77b5" />

## Schritt 4: Herausfinden, ob Zertifikate erstellt werden 

```
kubectl describe certificate example-tls
```
```
# muss auf True stehen 
kubectl get cert
```

<img width="565" height="60" alt="image" src="https://github.com/user-attachments/assets/8d492fdf-a051-4b04-95cf-a62bdb3d0964" />

```
# Certificate Request 
kubectl get cr
# da ist das Zertfikat drin 
kubectl get secret example-tls
kubectl get orders 
```

### Debugging 

  * Solange das Zertifikat nicht bestätigt bei der ACME-Anfrage (Challenge), seht ihr das noch unter

```
kubectl get challenges
```


## Schritt 5: Testen

   * Aufruf der Subdomain im Browser (mit https): z.B. https://jochen.app.do.t3isp.de/banana

## Ref: 

  * https://hbayraktar.medium.com/installing-cert-manager-and-nginx-ingress-with-lets-encrypt-on-kubernetes-fe0dff4b1924
