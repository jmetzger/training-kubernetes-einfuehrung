# Install with helm

```
helm repo add traefik https://traefik.github.io/charts

helm upgrade -n ingress --install traefik traefik/traefik --version 40.3.0 --create-namespace --skip-crds --reset-values

kubectl -n ingress get pods
kubectl -n ingress get svc
helm -n ingress status traefik 

# Use special crds helm chart instead, because it does not deploy crds for gateway-api by default
# We get an error on digitalocean doks
# Das funktioniert in neuen version nicht mehr weil last-applied zu gross waere
# helm -n ingress upgrade --install traefik-crds traefik/traefik-crds --version 1.18.0 --reset-values
# Workaround
helm template traefik-crds traefik/traefik-crds | kubectl -n ingress apply --server-side -f -
```
