# Install with helm

```
helm repo add traefik https://traefik.github.io/charts

helm upgrade -n ingress --install traefik traefik/traefik --version 38.0.2 --create-namespace --skip-crds --reset-values

# Use special crds helm chart instead, because it does not deploy crds for gateway-api by default
# We get an error on digitalocean doks
helm -n ingress upgrade --install traefik-crds traefik/traefik-crds --version 1.12.0 --reset-values 
```
