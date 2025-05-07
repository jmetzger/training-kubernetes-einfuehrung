# Exercise Sealed Secret with mariadb secrets  

## Prerequisites: MariaDB secrets done 

[MariaDB Secret](/kubectl-examples/07-mariadb-secret.md)

##  Based on mariadb secrets exercise 

```
cd
cd manifests/secrettest
```

```
# Cleanup
kubectl delete -f 02-deploy.yml
kubectl delete -f 01-secrets.yml
# rm
rm 01-secrets.yml 
```


```
# öffentlichen Schlüssel zum Signieren holen 
kubeseal --fetch-cert --controller-namespace=kube-system --controller-name=sealed-secrets > pub-sealed-secrets.pem
cat pub-sealed-secrets.pem 
```

```
# Secret - config erstellen mit dry-run, wird nicht auf Server angewendet (nicht an Kube-Api-Server geschickt) 
kubectl create secret generic mariadb-secret --from-literal=MARIADB_ROOT_PASSWORD=11abc432 --dry-run=client -o yaml > 01-top-secret.yaml
cat 01-top-secret.yaml 
```

```
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
kubectl get secret mariadb-secret -o yaml
```

```
kubectl exec -it deploy/mariadb-deployment -- env | grep ROOT
kubectl delete -f 01-top-secret-sealed.yaml
kubectl get secrets
kubectl get sealedsecrets 
```
