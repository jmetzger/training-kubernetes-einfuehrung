# 2 Kubernetes kubeconfig -> zu einer 

```
cp ~/.kube/config ~/.kube/config.bak

# Merge (KUBECONFIG mit beiden Dateien setzen)
KUBECONFIG=~/.kube/config1:~/.kube/config2 kubectl config view --flatten > ~/.kube/config-merged

# Als neue config verwenden
mv ~/.kube/config-merged ~/.kube/config
```

## Jetzt context anzeigen und auswählen

```
kubectl config get-contexts
kubectl config use-context <context-name>
```
