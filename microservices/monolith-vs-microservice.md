# Monolithische Architektur vs. Microservices Architektur

## Schaubild 

![Monolithisch vs. Microservices](https://d1.awsstatic.com/Developer%20Marketing/containers/monolith_1-monolith-microservices.70b547e30e30b013051d58a93a6e35e77408a2a8.png)

Quelle: AWS Amazon 

## Monolithische Architektur

  * Alle Prozesse eng miteinander verbunden.
  * Alles ist ein einziger Service 
  * Skalierung:
      * Gesamte Architektur muss skaliert werden bei Spitzen

## Herausforderung: Monolithische Architektur 

  * Verbesserung und Hinzufügen neuer Funktionen wird mit zunehmender Codebasis zunehmend komplexer 
  * Nachteil: Schwer zu experimentieren 
  * Nachteil: Hinderlich für die Umsetzung neuer Ideen/Konzepte 

## Vorteile: Monolithische Architektur  

   * Gut geeignet für kleinere Konzepte und Teams 
   * Gut geeignet, wenn Projekt nicht stark wächst.
   * Gut geeignet wenn Projekt durch ein kleines Team entwickelt wird.
   * Guter Ausgangspunkt für ein kleineres Projekt 
   * Mit einer MicroService - Architektur zu starten, kann hinderlich sein.

## Microservices 

  * Jede Anwendung wird in Form von eigenständigen Komponenten erstellt. 
  * Jeder Anwendungsprozess wird als Service ausgeführt
  * Services kommunizieren über schlanke API's miteinander 
  * Entwicklung in Hinblick auf Unternehmensfunktionen
  * Jeder Service erfüllt eine bestimmte Funktion.
  * Sie werden unabhängig voneinander ausgeführt, daher kann:
    * Jeder Service aktualisiert
    * bereitgestellt
    * skaliert werden   
 
## Eigenschaften von microservices 

  * Eigenständigkeit
  * Spezialisierung 

## Vorteil: Microservices 

  * Agilität
    * kleines Team sind jeweils für einen Service verantwortlich
    * können schnell und eigenverantwortlich arbeiten
    * Entwicklungszyklus wird verkürzt. 

  * Flexible Skalierung
    * Jeder Service kann unanhängig skaliert werden. 

  * Einfache Bereitstellung
    * kontinuierliche Integration und Bereitstellung
    * einfach:
      * neue Konzepte auszuprobieren und zurückzunehmen, wenn etwas nicht funktioniert. 
      
  * Technologische Flexibilität
    * Die Teams haben die Freiheit, das beste Tool zur Lösung ihrer spezifischen Probleme auszuwählen.
    * Infolgedessen können Teams, die Microservices entwickeln, das beste Tool für die jeweilige Aufgabe wählen.

  * Wiederverwendbarer Code
    * Die Aufteilung der Software in kleine, klar definierte Module ermöglicht es Teams, Funktionen für verschiedene Zwecke zu nutzen. 
    * Ein Service/Funktion als Baustein
    
  * Resilienz
    * Gut geplant/designed -> erhöht die Ausfallsicherheit 
    * Monolithisch: Eine Komponente fällt aus, kann zum Ausfall der gesamten Anwendung führen.
    * Microservice: kompletter Ausfall wird vermieden, nur einzelnen Funktionalitäten sind betroffen

## Nachteile: Microservices 

  * Höhere Komplexität 
  * Bei schlechter / nicht automatischer dokumentation kann man bei einer größeren Anzahl von Miroservices den Überblick der Zusammenarbeit verlieren
  * Aufwand: Architektur von Monolithisch nach Microservices IST Aufwand ! 
  * Aufwand Wartung und Monitoring (Kubernetes) 
  * Erhöhte Knowledge bzgl. Debugging. 
  * Fallback-Aufwand (wenn ein Service nicht funktioniert, muss die Anwendung weiter arbeiten können, ohne das andere Service nicht funktionieren)
  * Erhöhte Anforderung an Konzeption (bzgl. Performance und Stabilität) 
  * Wichtiges Augenmerk (Netzwerk-Performance) 

## Nachteile: Microservices in Kubernetes 

  * andere Anforderungen an Backups und Monitoring 
