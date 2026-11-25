# Gateway API mit Traefik: Trainer-Vorbereitung

Nur fuer den Trainer, einmalig vor der Uebung [Gateway API mit Traefik](05-gateway-api-traefik.md).
Voraussetzung: Traefik ist installiert (siehe `ingress/traefik/install-with-helm.md`).

## Schritt 1: Gateway-API-CRDs aktualisieren (nur DOKS)

DOKS bringt durch Cilium Gateway-API-CRDs in v1.2.1 mit. Traefik 3.7 braucht neuere (`TLSRoute` v1, `BackendTLSPolicy`).
Ohne Update bleibt die GatewayClass auf `Unknown`, und die Traefik-Logs zeigen `failed to list *v1.TLSRoute`.

```
helm template traefik-crds traefik/traefik-crds --set gatewayAPI=true | kubectl apply --server-side --force-conflicts -f -
kubectl get crd tlsroutes.gateway.networking.k8s.io -o jsonpath='{.spec.versions[*].name}'
# muss v1 enthalten
```

## Schritt 2: Gateway-Provider in Traefik einschalten

```
helm upgrade -n ingress traefik traefik/traefik --version 40.3.0 --reuse-values --skip-crds --set providers.kubernetesGateway.enabled=true
kubectl get gatewayclass
# traefik -> ACCEPTED True (die GatewayClass "cilium" ignorieren wir)
```

## Schritt 3: Gemeinsames Gateway anlegen

```
cat > gateway.yml <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: shared-gateway
  namespace: ingress
spec:
  gatewayClassName: traefik
  listeners:
    - name: web
      port: 8000
      protocol: HTTP
      allowedRoutes:
        namespaces:
          from: All
EOF
```

`port: 8000` ist der interne Traefik-Entrypoint `web`. `from: All` erlaubt Routen aus allen Namespaces.

```
kubectl apply -f gateway.yml
kubectl -n ingress get gateway shared-gateway
# PROGRAMMED True, ADDRESS = LoadBalancer-IP von Traefik
kubectl -n ingress get pods
# weiterhin nur ein Traefik-Pod, das Gateway erzeugt keinen
```

Hinweis: Das Chart legt selbst ein `traefik-gateway` an, das nur Routen aus dem Namespace `ingress` erlaubt.
Deshalb das eigene `shared-gateway`.

## Aufraeumen (nach dem Training)

```
kubectl -n ingress delete gateway shared-gateway
```
