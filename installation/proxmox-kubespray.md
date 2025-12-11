# Proxmox mit kubespray 

## Schritt 1: virtuellen Maschine deployen 

  * 4GB (control nodes eher 8GB) - minimaler Arbeitsspeicher
  * Debian als Betriebssystem
  * minimale Installation
  * ssh-server installiert (openssh-server)
  * sudo benutzer ohne Passwort für privilege Escalation (z.B. admin darf als root arbeiten)

## Info 1.1 Netzwerk 

   * Alle virtuellen Maschinen im gleichen Netzwerk (kein VLAN)
   * Kubernetes mit eigenem VLAN
   * Alternativ neuerdings: mit SDN (Performance beobachten !)

## Schritt 2: maschine für ansible deployen/nutzen 

   * private/public key erstellen und den public auf die maschinen aus Schritt 1 verteilen
   * ansible und git installieren
   * kubespray clonen oder docker image verwenden (dann braucht man kein ansible installieren)
   * apt update -y; apt install docker.io -y
   * Inventory rauskopieren und anpassen

```
[all]
# Master/Control Plane Node
kube-master ansible_host=192.168.1.10
# Worker Nodes
kube-worker1 ansible_host=192.168.1.11
kube-worker2 ansible_host=192.168.1.12

[kube_control_plane]
kube-master

[etcd]
kube-master

[kube_node]
kube-worker1
kube-worker2
```

```
# evtl config anpassen vornehmen in den group vars
# z.B. 
https://github.com/kubernetes-sigs/kubespray/blob/master/inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml
```

```
ansible-playbook -i inventory/mycluster/ cluster.yml -b -v \
  --private-key=~/.ssh/private_key
```

```
# zum hostsystem verbinden und die kubeconfig
# in der Regel
cd /home/<user-mit-dem-ich-installiert-habe>/.kube
cat config
```


