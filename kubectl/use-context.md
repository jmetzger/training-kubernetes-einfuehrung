# Work with different kubernetes - clusters (using use-context) 

```
## Zwei config in KUBECONFIG env variable
cd ~/.kube
mv config config.kubeadm 
export KUBECONFIG=~/.kube/config.kubeadm:~/.kube/config.doks

# wir sehen beide configs
kubectl config view

kubectl config view --flatten > config
unset KUBECONFIG

# alle Contexti anzeigen lassen 
kubectl config get-contexts 

kubectl config use-context do-fra1-cluster-bka  
kubectl cluster-info
kubectl get nodes 

kubectl config use-context kubernetes-admin@kubernetes
kubectl cluster-info
kubectl get nodes 
```
