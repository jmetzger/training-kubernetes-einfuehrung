# Security Best Practices 

```
6. Security (other stuff) 
6.1. Be sure upgrade your system and use the newest versions (OS / OpenShift) 
6.2. Setup Firewall rules, for the cluster components. (OpenShift) - 
https://docs.openshift.com/container-platform/4.16/installing/install_config/configuring-firewall.html

6.3. Do not install any components, that you do not Need (with helm)

6.4. Always download Images instead of using them locally. 

I think it also has to do with auth. When set to always, the pod will pull the image from the registry, hence it has to do auth and have valid credentials to actually get the image.
If the image is already in the node, and let's say permission has been removed to access that image for that node in the registry, a pod could still be created since the image is already there.

-> Wie sicherstellen, dass das gesetzt ist ? 
OPA Gateway 
```



```
6.5. Scan all your Images before using them

6.5.1. In development

6.5.2. CI / CD Pipeline 

6.5.3 Registry (when uploading them) 


6.6. Restrict ssh Access 
(no ssh-access to cluster nodes please  !)

6.7. Use NetworkPolicies 

https://docs.openshift.com/container-platform/4.12/networking/network_policy/about-network-policy.html
-> BUT: Use the specific Network Policies of your CNI 
```
