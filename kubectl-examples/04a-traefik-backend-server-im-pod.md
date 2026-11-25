# Traefik: Services und Backend-Server direkt im Pod auslesen

Baut auf [Ingress mit traefik](04-ingress-traefik-with-hostnames-deployment.md) auf
(`apple-service`, `banana-service` und `example-ingress` müssen laufen).

Getestet am 2026-11-25 auf dem KV-Trainingscluster (Traefik v3.7.4, Chart 40.3.0).

## Idee

Traefik liest Ingress, Services und EndpointSlices aus der Kubernetes-API und baut daraus
intern seine eigene Sicht: **Router** (Host/Pfad) -> **Service** -> **Server** (Pod-IP:Port).
Diese Sicht fragen wir direkt im Traefik-Pod über die Traefik-API ab. Traefik leitet also
**nicht** an die ClusterIP des Kubernetes-Service weiter, sondern direkt an die Pod-IPs.

## Step 1: Traefik-API intern im Pod freischalten

**Warum nicht `--api.insecure=true`?** Das wäre die Abkürzung: Traefik hängt die API dann selbst an
den Entrypoint `traefik`. Dafür müsste man aber die Traefik-Installation ändern (Helm-Upgrade,
Neustart des Pods). Auf einem geteilten Cluster wollen wir das nicht. Die API (`api@internal`) ist
immer eingebaut, es fehlt nur ein Router, der darauf zeigt. Den legen wir selbst an.

Per Default antwortet `/api` auf Port 8080 mit 404, weil kein Router darauf zeigt. Wir legen
einen IngressRoute auf den internen Service `api@internal` an. Der Entrypoint `traefik`
(Port 8080) ist nur im Pod erreichbar, nicht von außen. Traefik selbst wird nicht verändert.

```
nano traefik-api.yml
```

```
apiVersion: traefik.io/v1alpha1
kind: IngressRoute
metadata:
  name: traefik-api-intern
spec:
  entryPoints:
    - traefik
  routes:
    - match: PathPrefix(`/api`)
      kind: Rule
      services:
        - name: api@internal
          kind: TraefikService
```

```
kubectl apply -f traefik-api.yml
```

## Step 2: Im Traefik-Pod abfragen

Das Traefik-Image enthält `sh` und `wget` (BusyBox), aber kein `curl` und kein `jq`.

```
TPOD=$(kubectl -n ingress get pods -o name | grep traefik | head -1)
echo $TPOD

# Rohausgabe direkt im Pod
kubectl -n ingress exec $TPOD -- wget -qO- http://localhost:8080/api/http/services
```

Auf einem geteilten Cluster stehen hier die Services aller Teilnehmer. Der Name ist
`<namespace>-<service>-<port>@kubernetes`. Filter lokal mit jq:

```
kubectl -n ingress exec $TPOD -- wget -qO- http://localhost:8080/api/http/services \
  | jq '.[] | select(.name | test("apple|banana")) | {name, servers: .loadBalancer.servers, status: .serverStatus}'
```

Erwartet (IPs sind Beispiele):

```
{
  "name": "<euer-namespace>-apple-service-80@kubernetes",
  "servers": [ { "url": "http://10.114.0.20:5678" } ],
  "status": { "http://10.114.0.20:5678": "UP" }
}
```

Welcher Router (Host/Pfad) zeigt auf welchen Service?

```
kubectl -n ingress exec $TPOD -- wget -qO- http://localhost:8080/api/http/routers \
  | jq '.[] | select(.name | test("example-ingress")) | {name, rule, service}'
```

## Step 3: Mit Kubernetes vergleichen

```
kubectl get pods -o wide -l app=apple
kubectl get endpointslices -l kubernetes.io/service-name=apple-service
```

Die Server-URLs aus Traefik sind die Pod-IPs mit dem `targetPort` (5678), nicht der
Service-Port 80.

## Step 4: Skalieren und beobachten

```
kubectl scale deploy apple-app --replicas=3
kubectl get pods -o wide -l app=apple
```

Den Befehl aus Step 2 wiederholen: Es erscheinen jetzt 3 Server.

```
kubectl scale deploy apple-app --replicas=1
```

## Step 5: Aufräumen

```
kubectl delete -f traefik-api.yml
```
