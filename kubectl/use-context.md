# Work with different kubernetes - clusters (using use-context) 

```
## Zwei config in KUBECONFIG env variable 
export KUBECONFIG=~/.kube/config:~/.kube/config.doks

# wir sehen beide configs
kubectl config view

# Sicherheitsbackup 
cd ~/.kube 
mv config config.kubeadm
ls -la

kubectl config view --flatten > config
unset KUBECONFIG

kubectl config get-contexts 
kubectl config use-context do-fra1-single 

kubectl cluster-info
kubectl get nodes 

kubectl config use-context do-fra-bka-cluster
kubectl cluster-info
kubectl get nodes 
```
