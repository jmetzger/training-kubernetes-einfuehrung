# Install minikube on wsl2 

## Eventually update wsl

```
# We need the newest version of wsl as of 09.2022 
# because systemd was included there
# in powershell
wsl --shutdown
wsl --update 
wsl 
```

## Walkthrough (Step 1) - in wsl 

```
# as root  in wsl 
# sudo su -
echo "[boot]" >> /etc/wsl.conf
echo "systemd=true" >> /etc/wsl.conf
```

## Walkthrough (Step 2) - restart wsl 

```
# in powershell 
wsl --shutdown 
# takes a little bit longer now 
wsl
```

## Walkthrough (step 3) - Setup minikube 

```
# as unprivileged user, e.g. yourname 
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    
# key for rep
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

sudo apt-get update -y
sudo apt-get install -y docker-ce

sudo usermod -aG docker $USER && newgrp docker
sudo apt install -y conntrack

# Download the latest Minikube
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Make it executable
chmod +x ./minikube

# Move it to your user's executable PATH
sudo mv ./minikube /usr/local/bin/

#Set the driver version to Docker
minikube config set driver docker

# install minkube 
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# and start it 
minikube start 

# find out system pods 
kubectl get pods -A 

## Note: kubernetes works within docker now 
## you can figure this out by
docker container ls 
# Now exec into the container you see: e.g acec 
docker exec -it acec bash 
# within the container (docker runs within the container as well)
docker container ls 
```

## Reference 

  * No need to install systemd mentioned here.
  * https://www.virtualizationhowto.com/2021/11/install-minikube-in-wsl-2-with-kubectl-and-helm/
