# Monitoring with Elasticsearch (Fluentd) - EFK - Stack -> microk8s 

## Components of the ELK Stack 
 
  * E : Elasticsearch (Suchmaschine) 
  * F : Fluentd (Datensammler)
  * K : Kibana (Grafische Frontend für die Datenauswertung) 

## What is fluentd ? 

  * fluentd aggregates different data like (app logs, systems logs a.s.o) - see References 

## Walkthrough 

```
##  1. On microk8s cluster-server 

# in microk8s 1.24 you need to activate the community repo firstly
microk8s enable common 

# With microk8s you can enable this stack. 
microk8s enable fluentd 
```

```
## 2. on windows client 


# Activate wsl ubuntu subsystem on windows 
# and start ubuntu 
# in cmd.exe or powershell
wsl --install


# in ubuntu shell (open from icon ubuntu in windows) 
# change to root 
sudo su -
cd
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod u+x kubectl 
mv ./kubectl /usr/local/bin 

# now setup config for kubectl 
cd 
mkdir .kube
cd .kube
# on microk8s get config 
# microk8s config 
# and copy it to config
vi config 

# should work now
kubectl cluster-info 

# Tschakka ! 
# Now open a port-forwarding directly to your client
kubectl port-forward -n kube-system service/kibana-logging 8181:5601

# Bamm ! You can now open kibana in your local browser
# e.g. Chrome / Edge 
http://127.0.0.1:8181

```

```
# In interface 

# Click on left menu discover
# Create an index 
# it will already be available in the list 
# logstash-* 
# On page Step 2
# choose filter -> @timestamp (from dropdown)

# See also 
# scroll a bit to the screenshots !!
#https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes#step-4-creating-the-fluentd-# daemonset


# After that click on discover again !! 
# Left menu
Discover

```




## References:

  *
  * https://www.fluentd.org/architecture

## Alternatives (set it up step by step) 

  * https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes
  * 
