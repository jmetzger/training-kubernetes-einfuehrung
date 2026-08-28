# External Secrets Operator (ESO) mit AWS Secrets Manager + KMS einrichten

## Hintergrund

Secrets liegen zentral in **AWS Secrets Manager** (dort automatisch durch **AWS KMS**
verschlüsselt). Der **External Secrets Operator (ESO)**
läuft als Controller im Cluster, holt sich die aktuellen Werte über eine eng begrenzte
IAM-Rolle und legt daraus ein ganz normales Kubernetes-`Secret` an.

![Setup-Ablauf ESO + AWS Secrets Manager](img/04-eso-setup-ablauf.svg)

Die im Git-Manifest sichtbaren Ressourcen (`SecretStore`, `ExternalSecret`) enthalten
**nie** den Secret-Wert selbst — nur den Namen/ARN des AWS-Secrets.

---

## 1. AWS-Seite (einmalig, i.d.R. vom Cluster-Admin)

### 1.1 Secret in Secrets Manager anlegen

```
aws secretsmanager create-secret \
  --name prod/db-credentials \
  --secret-string '{"username":"app","password":"s3cr3t"}'
```

### 1.2 IAM Policy — Zugriff nur auf genau dieses Secret

```
# vi 01-eso-iam-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:GetSecretValue"],
      "Resource": "arn:aws:secretsmanager:eu-central-1:123456789012:secret:prod/db-credentials-*"
    }
  ]
}
```

```
aws iam create-policy \
  --policy-name eso-prod-db-credentials \
  --policy-document file://01-eso-iam-policy.json
```

### 1.3 IAM-Rolle für IRSA (IAM Roles for Service Accounts)

Die Trust Policy bindet die Rolle an den OIDC-Provider des EKS-Clusters und an genau
den ServiceAccount, den ESO später nutzt (Namespace + Name müssen exakt passen):

```
# vi 02-eso-trust-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/EXAMPLE1234"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-central-1.amazonaws.com/id/EXAMPLE1234:sub": "system:serviceaccount:external-secrets:eso-aws-sa"
        }
      }
    }
  ]
}
```

```
aws iam create-role \
  --role-name eso-prod-db-credentials \
  --assume-role-policy-document file://02-eso-trust-policy.json

aws iam attach-role-policy \
  --role-name eso-prod-db-credentials \
  --policy-arn arn:aws:iam::123456789012:policy/eso-prod-db-credentials
```

---

## 2. Kubernetes-Seite

### 2.1 External Secrets Operator per Helm installieren

```
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --wait
```

Das installiert den Operator **und** die CRDs `SecretStore`, `ClusterSecretStore` und
`ExternalSecret` (`apiVersion: external-secrets.io/v1`).

### 2.2 ServiceAccount mit IRSA-Annotation

```
# vi 03-eso-serviceaccount.yml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: eso-aws-sa
  namespace: external-secrets
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/eso-prod-db-credentials
```

```
kubectl apply -f 03-eso-serviceaccount.yml
```

### 2.3 SecretStore — Verbindung zu AWS Secrets Manager

```
# vi 04-eso-secretstore.yml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: external-secrets
spec:
  provider:
    aws:
      service: SecretsManager
      region: eu-central-1
      auth:
        jwt:
          serviceAccountRef:
            name: eso-aws-sa
```

```
kubectl apply -f 04-eso-secretstore.yml
kubectl get secretstore -n external-secrets
```

### 2.4 ExternalSecret — welches Secret, wie oft, wohin

```
# vi 05-eso-externalsecret.yml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: external-secrets
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: DB_USERNAME
      remoteRef:
        key: prod/db-credentials
        property: username
    - secretKey: DB_PASSWORD
      remoteRef:
        key: prod/db-credentials
        property: password
```

```
kubectl apply -f 05-eso-externalsecret.yml
kubectl get externalsecret -n external-secrets
kubectl get secret db-credentials -n external-secrets -o yaml
```

---

## 3. Im Pod nutzen (env / envFrom)

Ab hier ist es ein ganz normales Kubernetes-`Secret` — die Wege aus der
[Credentials-Übersicht](/kubernetes/secrets/credentials-overview.md) gelten unverändert:

```
# vi 06-eso-demo-pod.yml
apiVersion: v1
kind: Pod
metadata:
  name: eso-demo
  namespace: external-secrets
spec:
  containers:
  - name: demo
    image: nginx
    envFrom:
    - secretRef:
        name: db-credentials
```

```
kubectl apply -f 06-eso-demo-pod.yml
kubectl exec eso-demo -n external-secrets -- env | grep DB_
```

---

## Aufräumen

```
kubectl delete namespace external-secrets
aws iam detach-role-policy --role-name eso-prod-db-credentials --policy-arn arn:aws:iam::123456789012:policy/eso-prod-db-credentials
aws iam delete-role --role-name eso-prod-db-credentials
aws iam delete-policy --policy-arn arn:aws:iam::123456789012:policy/eso-prod-db-credentials
aws secretsmanager delete-secret --secret-id prod/db-credentials --force-delete-without-recovery
```

## Kurz zusammengefasst

| Ressource | apiVersion / Tool | Zweck |
|---|---|---|
| Helm Chart `external-secrets/external-secrets` | Helm Repo `https://charts.external-secrets.io` | Installiert Operator + CRDs |
| `ServiceAccount` mit `eks.amazonaws.com/role-arn` | Kubernetes | IRSA-Bindung an IAM-Rolle |
| `SecretStore` | `external-secrets.io/v1` | Verbindung zu AWS Secrets Manager |
| `ExternalSecret` | `external-secrets.io/v1` | Welches AWS-Secret → welches K8s-Secret |
