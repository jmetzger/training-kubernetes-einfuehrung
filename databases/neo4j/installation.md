# Installation 

## Community Version mit normalen Helm-Chart installieren 

 * https://artifacthub.io/packages/helm/neo4j-helm-charts/neo4j

### Für den Zugriff von aussen 

  *  Reverse Proxy installieren [Chart im Internet](https://artifacthub.io/packages/helm/neo4j-helm-charts/neo4j-reverse-proxy)

```
# ingress-values.yaml
reverseProxy:
  serviceName: "my-neo4j-admin"   # Name des Neo4j-Admin-Service
ingress:
  enabled: true
  className: traefik
  tls:
    enabled: true
    config:
      - secretName: neo4j-tls
        hosts:
          - neo4j.example.com
```

```
helm install neo4j-rp neo4j/neo4j-reverse-proxy -f ingress-values.yaml
```

## Enterprise Version 

  * Abweichende Werte in den values, aber ansonsten wie community

```
# enterprise-values.yaml
neo4j:
  name: my-neo4j
  password: "sicheres-passwort"
  edition: "enterprise"
  acceptLicenseAgreement: "yes"   # oder "eval" für Evaluierung
  resources:
    cpu: "2"
    memory: "4Gi"

volumes:
  data:
    mode: defaultStorageClass
    defaultStorageClass:
      requests:
        storage: 20Gi
```
