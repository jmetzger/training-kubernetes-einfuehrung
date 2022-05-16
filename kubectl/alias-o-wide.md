# Alias für kubectl get -o wide 

```
cd 
echo "alias kgw='kubectl get -o wide'" >> .bashrc
# for it to take immediately effect or relogin 
bash
kgw pods 
```
