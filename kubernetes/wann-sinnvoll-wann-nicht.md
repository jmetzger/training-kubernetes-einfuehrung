# Kubernetes - Wann sinnvoll, wann nicht ? 

## Wann nicht sinnvoll ? 

  * Anwendung, die ich nicht in Container "verpackt" habe  
  * Spielt der Dienstleister mit (Wartungsvertrag) 
  * Kosten / Nutzenverhältnis (Umstellen von Container zu teuer) 
  * Anwendung läßt sich nicht skalieren 
    * z.B. Bottleneck Datenbank  
    * Mehr Container bringen nicht mehr (des gleichen Typs) 
  
## Wo spielt Kubernetes seine Stärken aus ? 

  * Skalieren von Anwendungen. 
  * bessere Hochverfügbarkeit out-of-the-box
  * Heilen von Systemen (neu starten von Containern) 
  * Automatische Überwachung (mit deklarativem Management) - ich beschreibe, was ich will
  * Neue Versionen auszurollen (Canary Deployment, Blue/Green Deployment) 

## Mögliche Nachteile 

  * Steigert die Komplexität.
  * Debugging wird u.U. schwieriger
  * Mit Kubernetes erkaufe ich mir auch, die Notwendigkeit.
    * Über adequate Backup-Lösungen nachzudenken (Moving Target, Kubernetes Aware Backups) 
    * Bereitsstellung von Monitoring Daten Log-Aggregierungslösung 

## Klassische Anwendungsfällen (wo Kubernetes von Vorteil) 

  * Webbasierte Anwendungen (z.B. auch API's bzw. Web)
  * Ausser Problematik: Session StickyNess 
 



