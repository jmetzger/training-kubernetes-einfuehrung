# Helm - Example - Install bitnami/mysql 

## Prerequisites 

  * kubectl needs to be installed and configured to access cluster
  * Good: helm works as unprivileged user as well - Good for our setup 
  * install helm on ubuntu (client) as root: snap install --classic helm 
    * this installs helm3
  * Please only use: helm3. No server-side components needed (in cluster) 
    * Get away from examples using helm2 (hint: helm init) - uses tiller  

## Important commands 

```
# Repo hinzufpgen 
helm repo add bitnami https://charts.bitnami.com/bitnami 
# gecachte Informationen aktualieren 
helm repo update

helm search bitnami 
# helm install release-name bitnami/mysql
helm install my-mysql bitnami/mysql
# Chart runterziehen ohne installieren 
# helm pull bitnami/mysql

# Release anzeigen zu lassen
helm list 

# Status einer Release / Achtung, heisst nicht unbedingt nicht, dass pod läuft 
helm status my-mysql 

# weitere release installieren 
# helm install neuer-release-name  bitnami/mysql 


```

## Under the hood 

```
# Helm speichert Informationen über die Releases in den Secrets
kubectl get secrets | grep helm 


```


## Example 1: - To get know the structure 

```
helm repo add bitnami https://charts.bitnami.com/bitnami 
helm search repo bitnami 
helm repo update
helm pull bitnami/mysql 
tar xzvf mysql-9.0.0.tgz 

```



## Example 2: We will setup mysql without persistent storage (not helpful in production ;o() 

```
helm repo add bitnami https://charts.bitnami.com/bitnami 
helm search repo bitnami 
helm repo update

helm install my-mysql bitnami/mysql


```


## Example 2 - continue - fehlerbehebung 

```
helm uninstall my-mysql 
# Install with persistentStorage disabled - Setting a specific value 
helm install my-mysql --set primary.persistence.enabled=false bitnami/mysql

# just as notice 
# helm uninstall my-mysql 

```

## Example 2b: using a values file 

```
# mkdir helm-mysql
# cd helm-mysql
# vi values.yml 
primary:
  persistence:
    enabled: false 
```

```
helm uninstall my-mysql
helm install my-mysql bitnami/mysql -f values.yml 
```

## Example 3: Install wordpress 

```
helm repo add bitnami https://charts.bitnami.com/bitnami 
helm install my-wordpress \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
    bitnami/wordpress
```


## Referenced

  * https://github.com/bitnami/charts/tree/master/bitnami/mysql/#installing-the-chart
  * https://helm.sh/docs/intro/quickstart/
