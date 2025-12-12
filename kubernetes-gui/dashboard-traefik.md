# Kubernetes Dashboard (mit Traefik)

## Komplette Lösung mit korrekter Domain https://dashboard.do.t3isp.de

### Voraussetzung 

  * traefik ist installiert
  * htpasswd ist installiert (apt install apache2-utils)

### 1. RBAC 

```
nano dashboard-rbac.yaml
```

```
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dashboard-readonly
rules:
- apiGroups: [""]
  resources: [pods, pods/log, services, configmaps, secrets, persistentvolumeclaims, namespaces, nodes, events, endpoints, resourcequotas, limitranges, serviceaccounts]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: [deployments, daemonsets, replicasets, statefulsets]
  verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
  resources: [jobs, cronjobs]
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources: [ingresses, networkpolicies]
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources: [storageclasses, persistentvolumes]
  verbs: ["get", "list", "watch"]
- apiGroups: ["autoscaling"]
  resources: [horizontalpodautoscalers]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-readonly
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dashboard-readonly
subjects:
- kind: ServiceAccount
  name: dashboard-readonly
  namespace: kubernetes-dashboard
```

```
kubectl apply -f .
```

### 2. basic auth mit traefik 

```
kubectl create ns kubernetes-dashboard
```

```
#  basic auth in bas64 erstellen
kubectl create secret generic dashboard-basic-auth \
  --from-literal=users=$(htpasswd -nb admin DEIN-PASSWORT) \
  -n kubernetes-dashboard



### 1. values.yaml

```yaml
app:
  ingress:
    enabled: true
    ingressClassName: traefik
    hosts:
      - dashboard.do.t3isp.de
    tls:
      enabled: true
      secretName: dashboard-tls
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: dashboard-basic-auth
      nginx.ingress.kubernetes.io/auth-realm: "Dashboard Authentication"

api:
  containers:
    args:
      - --enable-skip-login
      - --disable-settings-authorizer

serviceAccount:
  create: false
  name: dashboard-readonly
```

### 2. dashboard-manifests.yaml

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: kubernetes-dashboard
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: dashboard-readonly
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: dashboard-readonly
rules:
- apiGroups: [""]
  resources:
    - pods
    - pods/log
    - services
    - configmaps
    - secrets
    - persistentvolumeclaims
    - namespaces
    - nodes
    - events
    - endpoints
    - resourcequotas
    - limitranges
    - serviceaccounts
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources:
    - deployments
    - daemonsets
    - replicasets
    - statefulsets
  verbs: ["get", "list", "watch"]
- apiGroups: ["batch"]
  resources:
    - jobs
    - cronjobs
  verbs: ["get", "list", "watch"]
- apiGroups: ["networking.k8s.io"]
  resources:
    - ingresses
    - networkpolicies
  verbs: ["get", "list", "watch"]
- apiGroups: ["storage.k8s.io"]
  resources:
    - storageclasses
    - persistentvolumes
  verbs: ["get", "list", "watch"]
- apiGroups: ["autoscaling"]
  resources:
    - horizontalpodautoscalers
  verbs: ["get", "list", "watch"]
- apiGroups: ["policy"]
  resources:
    - poddisruptionbudgets
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: dashboard-readonly
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: dashboard-readonly
subjects:
- kind: ServiceAccount
  name: dashboard-readonly
  namespace: kubernetes-dashboard
---
apiVersion: v1
kind: Secret
metadata:
  name: dashboard-basic-auth
  namespace: kubernetes-dashboard
type: Opaque
data:
  auth: YWRtaW46JGFwcjEkdGVzdCR0ZXN0  # Ersetzen!
```

### 3. Deployment

```bash
# Basic Auth generieren und base64 kodieren
htpasswd -nb admin DEIN_PASSWORT | base64

# Wert in dashboard-manifests.yaml eintragen, dann:
kubectl apply -f dashboard-manifests.yaml

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update

helm install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard \
  -n kubernetes-dashboard -f values.yaml
```

**Zugriff:** `https://dashboard.do.t3isp.de`
