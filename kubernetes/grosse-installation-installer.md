# Grosses Installation 

## Tanzuh (vmware) 

 * Lizenzkosten

### Alternative (Cluster API) 

  * 1 Management Cluster
  * jedes weiteres wird vom Management Cluster ausgerollt.
  * Beschreibung Deines Cluster als Konfiguration
  * feststehende images für die Basis des Clusters

#### Nachteile: 

   * nur auf der Kommandozeile
   * keinen Support

## Rancherlabs Ranger (SuSE) 

   * Grafische Weboberfläche (Management GUI)
     * mit Docker oder aber auch in einem cluster (z.B. helm - Chart)
   * kann eine oder mehrere Cluster verwalten
     * Installation: k3s
     * Installation: RKE2 

## OpenStack (Alternative: vmware) - OpenSource 

    * API für OpenStack (Nutzung dieser API über Terraform oder OpenTofu) - > Terraform -> Infrastructur as code. (.tf)  

### Schritt 1: virtuellen Maschinen ausrollen. 


### Schritt 2: Kubernetes ausrollen 

    * Ansible (leichter bestimmte zu Konfigurieren) 
    * kubeadm

## Proxmox 

### Schritt 1: virtuellen Maschinen ausrollen. 


### Schritt 2: Kubernetes ausrollen 

    * Kubespray (verwendet auch ansible aber direkt auf ansible abgestimmt)
    * Ansible (leichter bestimmte zu Konfigurieren) 
    * kubeadm

## Talos 

    * Installation mit iso 
    * immutable 
    


 
