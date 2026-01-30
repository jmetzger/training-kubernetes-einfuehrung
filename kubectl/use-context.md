# Work with different kubernetes - clusters (using use-context) 

```
## Zwei config in KUBECONFIG env variable 
export KUBECONFIG=~/.kube/config:~/.kube/config.doks
kubectl config view 
cp config config.kubeadm 
kbuectl config view --flatten > config
unset KUBECONFIG

kubectl config get-contexts 
kubectl config use-context do-fra1-single 

kubectl cluster-info
kubectl get nodes 

kubectl config use-context do-fra-bka-cluster
kubectl cluster-info
kubectl get nodes 
```
