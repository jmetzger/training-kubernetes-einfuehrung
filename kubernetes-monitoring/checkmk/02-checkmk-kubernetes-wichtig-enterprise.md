# Features in Checkmk bzgl. Kubernetes

## Prerequisites

  * Use at least version 2.1 of checkmk

## Spoiler Alert

   * Kubernetes läßt sich in checkmk nur gut monitoren mit der checkmk Enterprise - Version

## Was hat die checkmk Enterprise gegenüber der Raw-Version besonderes für Kubernetes

  * Spezielle Kubernetes Dashboard, bereits fix und fertig. (Ansonsten sehr viel Arbeit nachzubauen)
  * Noch wichtiger: Dynamic Host Management

### Dynamic Host Management

  * Neues Pods werden automatisch erkannt (auch Services, Deployments usw.)
  * Resourcen, die nicht mehr da sind, werden automatisch rausgelöscht.

### Alternative Dynamic Host Management: Ich müsste das händisch machen bzw. selbst scripten

  * Ich müsste rest-api call ausführen, um dies über die api von check zu setzen.
  * Neue Hosts müßte ich discovern, alte rauslöschen (automatisch)

### Alternative: Dashboards

  * Dashboards selber bauen
  * Grafana mit checkmk - Daten (Aus meiner Sicht wenig praktikabel, dann entweder ganz Grafana  + Prometheus oder checkmk Enterprise)
