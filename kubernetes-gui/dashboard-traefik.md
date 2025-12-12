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
```

### 3. middleware für traefik 


```
nano middleware.yaml
```

```
apiVersion: traefik.io/v1alpha1
kind: Middleware
metadata:
  name: dashboard-auth
  namespace: kubernetes-dashboard
spec:
  basicAuth:
    secret: dashboard-basic-auth
```

```
kubectl apply -f .
```


### 4. dashboard installieren 

```
nano values.yaml
```

```yaml
# values.yaml
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
      traefik.ingress.kubernetes.io/router.middlewares: kubernetes-dashboard-dashboard-auth@kubernetescrd

# Neuere Chart-Versionen
extras:
  - |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: kubernetes-dashboard-settings
    data:
      settings: '{"skipLoginPage":true}'

serviceAccount:
  create: true
  name: dashboard-readonly
```

```yaml
# values.yaml
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
      traefik.ingress.kubernetes.io/router.middlewares: kubernetes-dashboard-dashboard-auth@kubernetescrd

api:
  containers:
    args:
      - --enable-skip-login
      - --disable-settings-authorizer

serviceAccount:
  create: true
  name: dashboard-readonly
```

```
helm repo add k8s-dashboard https://kubernetes.github.io/dashboard
helm upgrade --install kubernetes-dashboard k8s-dashboard/kubernetes-dashboard \
  -n kubernetes-dashboard -f values.yaml --reset-values --version 7.14.0
```



**Zugriff:** `https://dashboard.do.t3isp.de`
