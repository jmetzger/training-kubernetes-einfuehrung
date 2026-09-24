# Prometheus + Grafana mit Ingress und BasicAuth (Helm)

**Hinweis:** Der Alertmanager-Teil (Schritt 6) ist aus dem Q3-Advanced-Training uebernommen und an
unser DOKS-Setup angepasst (kein MetalLB, kein Wildcard-DNS-Script), aber noch nicht live auf
diesem Cluster nachgetestet - insbesondere den tatsaechlichen Alertmanager-Service-Namen vor dem
Training einmal per `kubectl get svc` verifizieren.

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
  -f values.yml --namespace monitoring --create-namespace --version 86.3.1
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

## Schritt 6: Alertmanager Ingress (gleiche Middleware wiederverwenden)

Die `Middleware` aus Schritt 5 ist nicht an einen Service gebunden - sie laesst sich 1:1 auch am
Alertmanager-Ingress referenzieren.

Erst den tatsaechlichen Service-Namen pruefen (haengt vom `fullnameOverride` in der values.yml ab):

```
kubectl -n monitoring get svc | grep alertmanager
```

```
vi alertmanager-ingress.yml
```

```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: alertmanager-ingress
  namespace: monitoring
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/router.middlewares: monitoring-prometheus-auth@kubernetescrd
spec:
  ingressClassName: traefik
  tls:
  - hosts:
    - alertmanager.<dein-name>.do.t3isp.de
    secretName: alertmanager-tls
  rules:
  - host: alertmanager.<dein-name>.do.t3isp.de
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: alertmanager-alertmanager   # ggf. an den Namen aus obigem kubectl get svc anpassen
            port:
              number: 9093
```

```
kubectl apply -f alertmanager-ingress.yml -n monitoring
```

Der kube-prometheus-stack legt automatisch eine `Watchdog`-Alert an, die dauerhaft feuert - guter
Beweis dafuer, dass die Alerting-Pipeline lebt:

![Alertmanager mit der staendig aktiven Watchdog-Alert](screenshots/06-alertmanager.png)

## Schritt 7: Zertifikate pruefen

```
# Alle drei Zertifikate muessen READY=True sein
kubectl -n monitoring get cert
```

## Schritt 8: Credentials nachschlagen (falls vergessen)

```
# Grafana-Passwort aus dem Kubernetes Secret auslesen:
kubectl -n monitoring get secret grafana -o jsonpath="{.data.admin-password}" | base64 -d
echo ""
```

```
# Prometheus BasicAuth: Benutzername ist immer "admin",
# Passwort ist das, das du in Schritt 4 mit htpasswd gesetzt hast.
# Zur Erinnerung: es steht auch in deiner values.yml unter adminPassword
```

## Schritt 10: Testen

```
# Ohne Credentials -> 401 (Zugang verweigert)
curl -s -o /dev/null -w "%{http_code}" https://prometheus.<dein-name>.do.t3isp.de

# Mit Credentials -> 200 (Zugang erlaubt)
curl -u admin:DEIN-PASSWORT -s -o /dev/null -w "%{http_code}" https://prometheus.<dein-name>.do.t3isp.de
```

Ohne Auth kommt ein sauberes 401 direkt von der Traefik-Middleware (nicht von Prometheus selbst):

![Prometheus ohne Basic-Auth: 401 Unauthorized von Traefik](screenshots/04-prometheus-401.png)

```
# Alertmanager genauso testen:
curl -s -o /dev/null -w "%{http_code}" https://alertmanager.<dein-name>.do.t3isp.de
curl -u admin:DEIN-PASSWORT -s -o /dev/null -w "%{http_code}" https://alertmanager.<dein-name>.do.t3isp.de
```

```
# Grafana im Browser aufrufen:
https://grafana.<dein-name>.do.t3isp.de
# Login: admin / DEIN-PASSWORT
```

![Grafana Login](screenshots/01-grafana-login.png)

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
