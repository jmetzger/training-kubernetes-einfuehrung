# Work with different kubernetes - clusters (using use-context) 

```
## Zwei config in KUBECONFIG env variable 
export KUBECONFIG=~/.kube/config:~/.kube/config.single
kubectl config view 
cp config config.bkup 
kbuectl config view --flatten > config.yaml 
kubectl config get-contexts 
kubectl config use-context do-fra1-single 
kubectl get nodes 
kubectl config use-context do-fra-bka-cluster 
```
