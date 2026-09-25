# Trainer-Setup: Registry im Cluster fuer die helm push Uebung

Einmalig pro Training vom Trainer auszufuehren. Voraussetzungen im Cluster:
Traefik als Ingress-Controller, cert-manager mit ClusterIssuer `letsencrypt-prod`,
Wildcard-DNS `*.appv2.do.t3isp.de` auf den Ingress-LoadBalancer.

Die Registry (`registry:2`) bekommt Basic Auth per htpasswd, einen Ingress mit
Let's-Encrypt-Zertifikat und ein Volume, damit die Charts einen Pod-Neustart
ueberleben.

## Schritt 1: Namespace und Zugangsdaten

```
cd
git clone https://github.com/jmetzger/training-kubernetes-einfuehrung.git
cd training-kubernetes-einfuehrung/helm/commands
```

```
kubectl create namespace registry
htpasswd -Bbc /tmp/htpasswd training helm-push-2026
kubectl -n registry create secret generic registry-auth --from-file=htpasswd=/tmp/htpasswd
rm /tmp/htpasswd
```

## Schritt 2: Registry ausrollen

Manifeste liegen in [push-registry/](push-registry/): PVC, Deployment, Service, Ingress.

```
kubectl apply -f push-registry -n registry
kubectl -n registry rollout status deployment registry
kubectl -n registry get certificate
```

Das Zertifikat braucht ein paar Minuten (HTTP-01 Challenge). Sobald `READY` auf `True` steht:

```
curl -u training:helm-push-2026 https://registry.appv2.do.t3isp.de/v2/_catalog
```

**Erwartete Ausgabe:**
```
{"repositories":[]}
```

## Aufraeumen (nach dem Training)

```
kubectl delete namespace registry
```
