# Wie geht bei Traefik mit RBA 

  * Service Account wird in den Pod gehängt
  * Und das was dieser ServiceAccount darf, darf der Pod auch über z.B. ein kubectl call machen

## Weg der Berechtigung 

```
Service Account -> Rolebinding/ClusterRolebinding -> ClusterRole/Role
```


## Schritte zur Analyse

```
# wie ist das eingentlich beim ingress controller 
# Welche ServiceAccount
kubectl -n ingress get sa traefik
# Wurde ClusterRole und Role verwendet - ClusterRole ist Serverweit 
helm -n ingress get manifest traefik | grep -i -A 4 kind
# Das darf dieser Rolle 
kubectl  get clusterrole traefik-ingress -o yaml
# Rolle wird mit User verknüpft, dadurch darf der User das, was die Rolle darf 
kubectl get clusterrolebinding traefik-ingress -o yaml

```
