# Prometheus + Grafana mit Ingress und BasicAuth (Helm)

## Voraussetzungen

  * Traefik installiert (Namespace `ingress`)
  * cert-manager installiert + ClusterIssuer `letsencrypt-prod` vorhanden (aus Uebung: https-letsencrypt-ingress-traefik)
  * `htpasswd` installiert: `apt install apache2-utils`

## Schritt 1: Vorbereitung

```
cd
mkdir -p manifests/monitoring
cd manifests/monitoring
```

## Schritt 2: values.yml erstellen

```
vi values.yml
```

```
fullnameOverride: prometheus

alertmanager:
  fullnameOverride: alertmanager

grafana:
  fullnameOverride: grafana
  adminPassword: DEIN-PASSWORT
  ingress:
    enabled: true
    ingressClassName: traefik
    hosts:
      - grafana.<dein-name>.do.t3isp.de
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    tls:
    - secretName: grafana-tls
      hosts:
      - grafana.<dein-name>.do.t3isp.de

kube-state-metrics:
  fullnameOverride: kube-state-metrics

prometheus-node-exporter:
  fullnameOverride: node-exporter
```

## Schritt 3: Prometheus-Stack installieren

```
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus prometheus-community/kube-prometheus-stack \
  -f values.yml --namespace monitoring --create-namespace --version 61.3.1
```

```
kubectl -n monitoring get pods
```

## Schritt 4: BasicAuth Secret fuer Prometheus erstellen

```
kubectl create secret generic prometheus-basic-auth \
  --from-literal=users="$(htpasswd -nb admin DEIN-PASSWORT)" \
  -n monitoring
```

## Schritt 5: Traefik Middleware + Prometheus Ingress

```
vi prometheus-ingress.yml
```

```
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: prometheus-auth
  namespace: monitoring
spec:
  basicAuth:
    secret: prometheus-basic-auth
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus-ingress
  namespace: monitoring
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.middlewares: monitoring-prometheus-auth@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - prometheus.<dein-name>.do.t3isp.de
    secretName: prometheus-tls
  rules:
  - host: prometheus.<dein-name>.do.t3isp.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: prometheus-prometheus
            port:
              number: 9090
```

```
kubectl apply -f prometheus-ingress.yml -n monitoring
```

## Schritt 6: Zertifikate pruefen

```
# Beide Zertifikate muessen READY=True sein
kubectl -n monitoring get cert
```

## Schritt 7: Testen

```
# Ohne Credentials -> 401 (Zugang verweigert)
curl -s -o /dev/null -w "%{http_code}" https://prometheus.<dein-name>.do.t3isp.de

# Mit Credentials -> 200 (Zugang erlaubt)
curl -u admin:DEIN-PASSWORT -s -o /dev/null -w "%{http_code}" https://prometheus.<dein-name>.do.t3isp.de
```

```
# Grafana im Browser aufrufen:
https://grafana.<dein-name>.do.t3isp.de
# Login: admin / DEIN-PASSWORT
```

## Hintergrund: Warum BasicAuth fuer Prometheus?

Grafana hat einen eigenen Login (Benutzerverwaltung, Rollen, Sessions).
Prometheus hat kein eingebautes Authentication-System.
Traefik loest das ueber eine `Middleware` -- kein extra Pod noetig.

Das Muster: Secret (htpasswd) -> Middleware CRD -> Ingress-Annotation

## Aufraeumen

```
kubectl delete namespace monitoring
```

## Referenzen

  * https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md
  * https://doc.traefik.io/traefik/middlewares/http/basicauth/
