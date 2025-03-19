# Installation mit kubeadm (CNI: calico) 

## Version 

  * Ubuntu 20.04 LTS 

## Done for you 

  * Servers are setup:
    * ssh-running
    * kubeadm, kubelet, kubectl installed
    * containerd - runtime installed 

  * Installed on all nodes (with cloud-init)

```
#!/bin/bash 

groupadd sshadmin
USERS="mysupersecretuser"
SUDO_USER="mysupersecretuser"
PASS="yoursupersecretpass"
for USER in $USERS
do
  echo "Adding user $USER"
  useradd -s /bin/bash --create-home $USER
  usermod -aG sshadmin $USER
  echo "$USER:$PASS | chpasswd
done

# We can sudo with $SUDO_USER
usermod -aG sudo $SUDO_USER

# 20.04 and 22.04 this will be in the subfolder
if [ -f /etc/ssh/sshd_config.d/50-cloud-init.conf ]
then
  sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config.d/50-cloud-init.conf
fi

## both is needed 
sed -i "s/PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config

usermod -aG sshadmin root

# TBD - Delete AllowUsers Entries with sed 
# otherwice we cannot login by group 

echo "AllowGroups sshadmin" >> /etc/ssh/sshd_config 
systemctl reload sshd

# Now let us do some generic setup
echo "Installing kubeadm kubelet kubectl"

### A lot of stuff needs to be done here
### https://www.linuxtechi.com/install-kubernetes-on-ubuntu-22-04/

# 1. no swap please
swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Loading necessary modules
echo "overlay" >> /etc/modules-load.d/containerd.conf
echo "br_netfilter" >> /etc /modules-load.d/containerd.conf
modprobe overlay
modprobe br_netfilter

# 3. necessary kernel settings
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf
sysctl --system

# 4. Update the meta-information
apt-get -y update

# 5. Installing container runtime
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"       apt-get install -y containerd.io

# 6. Configure containerd
containerd config default > /etc/containerd/config.toml
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 7. Add Kubernetes Repository for Kubernetes
mkdir -m 755 /etc/apt/keyrings
apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSI                                                                                                               # 8. Install kubectl kubeadm kubectl
apt-get -y update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold -y kubelet kubeadm kubectl

# 9. Install helm
snap install helm --classic

# Installing nfs-common
apt-get -y install nfs-common
```


## Prerequisites 

  * 4 Servers setup and reachable through ssh.
  * user: 11trainingdo
  * pass: PLEASE ask your instructor 


```
# Important - Servers are not reachable through
# Domain !! Only IP. 
controlplane.tln<nr>.t3isp.de 
worker1.tln<nr>.do.t3isp.de
worker2.tln<nr>.do.t3isp.de
worker3.tln<nr>.do.t3isp.de
```

## Step 1: Setup controlnode (login through ssh) 

```
# This CIDR is the recommendation for calico
# Other CNI's might be different 
CLUSTER_CIDR="192.168.0.0/16"

kubeadm init --pod-network-cidr=$CLUSTER_CIDR && \
  mkdir -p /root/.kube && \
  cp -i /etc/kubernetes/admin.conf /root/.kube/config && \
  chown $(id -u):$(id -g) /root/.kube/config && \
  cp -i /root/.kube/config /tmp/config.kubeadm && \
  chmod o+r /tmp/config.kubeadm 
```

```
# Copy output of join (needed for workers) 
# e.g. 
kubeadm join 159.89.99.35:6443 --token rpylp0.rdphpzbavdyx3llz \
        --discovery-token-ca-cert-hash sha256:05d42f2c051a974a27577270e09c77602eeec85523b1815378b815b64cb99932
```

## Step 2: Setup worker1 - node (login through ssh) 

```
# use join command from Step 1:
kubeadm join 159.89.99.35:6443 --token rpylp0.rdphpzbavdyx3llz \
        --discovery-token-ca-cert-hash sha256:05d42f2c051a974a27577270e09c77602eeec85523b1815378b815b64cb99932
```

## Step 3: Setup worker2 - node (login through ssh) 

```
# use join command from Step 1:
kubeadm join 159.89.99.35:6443 --token rpylp0.rdphpzbavdyx3llz \
        --discovery-token-ca-cert-hash sha256:05d42f2c051a974a27577270e09c77602eeec85523b1815378b815b64cb99932
```

## Step 4: Setup worker3 - node (login through ssh) 

```
# use join command from Step 1:
kubeadm join 159.89.99.35:6443 --token rpylp0.rdphpzbavdyx3llz \
        --discovery-token-ca-cert-hash sha256:05d42f2c051a974a27577270e09c77602eeec85523b1815378b815b64cb99932
```

## Step 5: CNI-Setup (calico) on controlnode (login through ssh) 

```
kubectl get nodes 
```

```
# Output
root@controlplane:~# kubectl get nodes
NAME           STATUS     ROLES           AGE     VERSION
controlplane   NotReady   control-plane   6m27s   v1.28.6
worker1        NotReady   <none>          3m18s   v1.28.6
worker2        NotReady   <none>          2m10s   v1.28.6
worker3        NotReady   <none>          60s     v1.28.6
```

```
# Installing calico CNI 
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml
kubectl get ns
kubectl -n calico-system get all
kubectl -n calico-system get pods -o wide -w 
```

```
# After if all pods are up and running -> CTRL + C
```

```
kubectl -n calico-system get pods -o wide
# all nodes should be ready now 
kubectl get nodes -o wide 
```

```
# Output
root@controlplane:~# kubectl get nodes
NAME           STATUS   ROLES           AGE    VERSION
controlplane   Ready    control-plane   14m    v1.28.6
worker1        Ready    <none>          11m    v1.28.6
worker2        Ready    <none>          10m    v1.28.6
worker3        Ready    <none>          9m9s   v1.28.6
```

## Do it with ansible 

  * https://spacelift.io/blog/ansible-kubernetes
