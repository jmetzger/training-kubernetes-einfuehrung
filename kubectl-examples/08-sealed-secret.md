# Sealed Secret 

##  Based on mariadb secrets exercise 

```
# Cleanup
kubectl delete -f 02-deploy.yml
kubectl delete -f 01-secrets.yml
# rm
rm 01-secrets.yml 
```


```
kubeseal --fetch-cert 

# Secret - config erstellen mit dry-run, wird nicht auf Server angewendet (nicht an Kube-Api-Server geschickt) 
kubectl create secret generic mariadb-secret --from-literal=MARIADB_ROOT_PASSWORD=11abc432 --dry-run=client -o yaml > 01-top-secret.yml
cat 01-top-secret.yaml 

# öffentlichen Schlüssel zum Signieren holen 
kubeseal --fetch-cert > pub-sealed-secrets.pem
cat pub-sealed-secrets.pem 

kubeseal --format=yaml --cert=pub-sealed-secrets.pem < 01-top-secret.yaml > 01-top-secret-sealed.yaml
cat 01-top-secret-sealed.yaml 

# Ausgangsfile von dry-run löschen 
rm 01-top-secret.yaml

# Ist das secret basic-auth vorher da ? 
kubectl get secrets mariadb-secret  

kubectl apply -f .

# Kurz danach erstellt der Controller aus dem sealed secret das secret 
kubectl get secret

kubectl get sealedsecrets 
kubectl get secret -o yaml
```

