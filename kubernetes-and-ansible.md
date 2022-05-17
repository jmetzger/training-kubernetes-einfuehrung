# Kubernetes and Ansible 

## Warum ?

  * Hilft mir mein Cluster auszurollen (Infrastruktur) 
  * Verwalten der gesamten Applikation (manifeste etc.) über Ansible 

## Für Infrastruktur 

  * Hervorragende Lösung. Erleichtert die Deployment-Zeit. 
  * Möglichst schlank und einfach mit Module halten,
    * z.B. https://docs.ansible.com/ansible/latest/collections/community/aws/aws_eks_cluster_module.html

## Empfehlungen Applikation 

  * Eigenes Repos mit manifesten.
  * Vorteil: Entwickler und andere Teams können das gleiche Repo verwenden 
  * Kein starkes Solution-LockIn.
  * Denkbar: Das dann ansible darauf zugreift. 

## Fragen Applikation 

  * Zu klären: Wie läuft der LifeCycle.
  * Wie werden neue Versionen ausgerollt ? -> Deployment - Prozess  

## Empfehlung Image 

  * Bereitstellen über Registry (nicht repo ansible) 
  * Binaries gehören nicht in repos (git kann das nicht so gut) 
