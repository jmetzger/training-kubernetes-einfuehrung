# 12-factor-app Prinzipien 

  * Das sind best-practices 

```
Die 12-Factors stammen von Heroku 
und beschreiben, wie eine App aussehen muss, 
damit sie sich problemlos in einer Cloud-Plattform betreiben lässt 
— also genau das, was Kubernetes heute von einem Workload erwartet.
```

  * Ursprünglich entwickelt von heroku 2011
  * Ursprünglich gedacht für cloud-native apps
  * Auch gut für microservices anwendbar

## Anwendung 

  * Checkliste: Gilt das für meinen Service ? 

Hier ist die Tabelle der Twelve-Factor App Principles:

| # | Prinzip | Beschreibung |
|---|---------|--------------|
| 1 | Codebase | Versionsverwaltetes Code-Repository |
| 2 | Dependencies | Abhängigkeiten sollten extern verwaltet werden. <br/> (spielte zur Zeit von heroku eine Rolle, weil Software auf dem Host ausgeführt wurde. Man soll sich also nicht darauf verlassen, was auf dem Host existiert. Bei Docker/Kubernetes ist das bereits im Container-Image selbst geregelt. Man könnte also sagen, die Regel ist bei Docker-Images ohnehin erfüllt.|
| 3 | Config | Konfiguration als Umgebungsvariablen |
| 4 | Backing Services | Datenbanken, Messaging etc. als externe Ressourcen |
| 5 | Build, Release, Run | Drei unabhängige Deployment-Schritte |
| 6 | Stateless Processes | Zustandslose, unabhängige Prozesse zum guten Skalieren |
| 7 | Port Binding | App bindet direkt an Port |
| 8 | Concurrency | Apps sollten in Module aufgeteillt werden zur einfachen Skalierung |
| 9 | Disposability | Schneller Start und einfaches Herunterfahren |
| 10 | DEV/PROD Parity | Entwicklungumgebung und Produktion möglichst ähnlich |
| 11 | Logs | Logs als Event-Streams behandeln (wie bei docker / kubernetes) |
| 12 | Admin Processes | Admin-Aufgaben als One-off-Prozesse <br/> Einmalige Aktion möglichst gescriptet und versioniert und sie sollten in der gleichen Umgebung 
umgesetzt werden. <br/> Job/Cronjob/initContainer |
