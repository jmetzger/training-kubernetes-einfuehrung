# Kubernetes - Wann sinnvoll, wann nicht ? 

## Wann nicht sinnvoll ? 

  * Anwendung, die ich nicht in Container verpacken 
  * Spielt der Dienstleistung (Wartungsvertrag) 
  * Kosten / Nutzenverhältnis (Umstellen von Container zu teuer) 
  * Anwendung läßt sich nich skalieren 
    * z.B. Bottleneck Datenbank  
    * Mehr Container bringen nicht mehr (des gleichen Typs) 
  
## Wo spielt Kubernetes seine Stärken aus ? 

  * Skalieren von Anwendungen. 
  * Heilen von Systemen (neu starten von Pods) 
  * Automatische Überwachung mit deklaraktivem Management) - ich beschreibe, was ich will
  * Neue Versionen zu auszurollen (Canary Deployment, Blue/Green Deployment) 

## Mögliche Nachteile 

  * Steigert die Komplexität.
  * Debugging wird u.U. schwieriger
  * Mit Kubernetes erkaufe ich mir auch, die Notwendigkeit.
    * Über adequate Backup-Lösungen nachzudenken (Moving Target, Kubernetes Aware Backups) 
    * Bereitsstellung von Monitoring Daten Log-Aggregierungslösung 

## Klassische Anwendungsfällen 

  * Webbasierte Anwendungen (z.B. auch API's bzw. Web)
 



