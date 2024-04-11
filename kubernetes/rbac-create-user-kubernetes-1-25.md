# RBAC - Create user for kubeconfig with restricted permissions

## Enable RBAC in microk8s 

```
# This is important, if not enable every user on the system is allowed to do everything 
microk8s enable rbac 
```

## Schritt 1: Nutzer-Account auf Server anlegen und secret anlegen / in Client 

```
cd 
mkdir -p manifests/rbac
cd manifests/rbac
```

###  Mini-Schritt 1: Definition für Nutzer 

```
# vi service-account.yml 
apiVersion: v1
kind: ServiceAccount
metadata:
  name: training<nr>
  namespace: default
```

```
kubectl apply -f service-account.yml 
```

### Mini-Schritt 1.5: Secret erstellen 

  * From Kubernetes 1.25 tokens are not created automatically when creating a service account (sa)
  * You have to create them manually with annotation attached 
  * https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#create-token

```
# vi secret.yml 
apiVersion: v1
kind: Secret
type: kubernetes.io/service-account-token
metadata:
  name: trainingtoken<nr>
  namespace: default
  annotations:
    kubernetes.io/service-account.name: training<nr>
```

```
kubectl apply -f .
```


### Mini-Schritt 2: ClusterRole festlegen - Dies gilt für alle namespaces, muss aber noch zugewiesen werden

```
## Bevor sie zugewiesen ist, funktioniert sie nicht - da sie keinem Nutzer zugewiesen ist 

# vi pods-clusterrole.yml 
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: pods-clusterrole<nr>
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list", "create"]
```

```
kubectl apply -f pods-clusterrole.yml 
```

### Mini-Schritt 3: Die ClusterRolle den entsprechenden Nutzern über RoleBinding zu ordnen 
```
# vi rb-training-ns-default-pods.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: rolebinding-ns-default-pods<nr>
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pods-clusterrole<nr> 
subjects:
- kind: ServiceAccount
  name: training<nr>
  namespace: default
```

```
kubectl apply -f rb-training-ns-default-pods.yml
```

### Mini-Schritt 4: Testen (klappt der Zugang) 

```
kubectl auth can-i get pods -n default --as system:serviceaccount:default:training<nr>
```

## Schritt 2: Context anlegen / Credentials auslesen und in kubeconfig hinterlegen (ab Kubernetes-Version 1.25.) 

### Mini-Schritt 1: kubeconfig setzen 

```
kubectl config set-context training-ctx --cluster microk8s-cluster --user training

# extract name of the token from here 

TOKEN=`kubectl get secret trainingtoken<nr> -o jsonpath='{.data.token}' | base64 --decode`
echo $TOKEN
kubectl config set-credentials training --token=$TOKEN
kubectl config use-context training-ctx

# Hier reichen die Rechte nicht aus 
kubectl get deploy
# Error from server (Forbidden): pods is forbidden: User "system:serviceaccount:kube-system:training" cannot list # resource "pods" in API group "" in the namespace "default"
```

### Mini-Schritt 2:
```
kubectl config use-context training-ctx
kubectl get pods 
```

### Mini-Schritt 3: Zurück zum alten Default-Context 

```
kubectl config get-contexts
```

```
CURRENT   NAME           CLUSTER            AUTHINFO    NAMESPACE
          microk8s       microk8s-cluster   admin2
*         training-ctx   microk8s-cluster   training2
```

```
kubectl config use-context microk8s  
```


## Refs:

  * https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengaddingserviceaccttoken.htm
  * https://microk8s.io/docs/multi-user
  * https://faun.pub/kubernetes-rbac-use-one-role-in-multiple-namespaces-d1d08bb08286

## Ref: Create Service Account Token 

  * https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/#create-token
