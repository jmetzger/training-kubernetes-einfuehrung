# Ablauf helm install 

## Grafik 

![](/images/helm_flowchart_300px.jpg)

## Der Weg 

Wenn der Befehl `helm install` ausgeführt wird, passiert intern Folgendes:

1. **Chart-Abfrage**:
    * Helm sucht Chart lokal oder im Repos und lädt es herunter.
1. **Chart-Templating**:
    * Helm rendert die Templates im Chart.
    * Variablen werden (wie in der `values.yaml` definiert) in die Templates eingefügt.
    * Dadurch werden manifeste für Kubernetes-Ressourcen (z. B. Deployments, Services) erstellt.
1. **Kubernetes API**:
   * Das gerenderte Kubernetes Manifest wird an den Kubernetes-API geschickt.
1. **Release-Verwaltung**:
   * Helm speichert die Chart- und Versionsinformationen in der Helm-Release-Datenbank (in Kubernetes als Secret)
   * Dies ermöglicht eine spätere Verwaltung und Aktualisierung des Releases.
1. **Ausgabe** (templates/NOTES.txt):
   * Helm gibt den Status des Installationsprozesses aus, einschließlich der erstellten Ressourcen und etwaiger Fehler.

## Long story short 

  * Helm rendert Kubernetes-Ressourcen aus einem Chart und kommuniziert mit der Kubernetes-API, um diese Ressourcen zu erstellen und ein Release zu verwalten.
