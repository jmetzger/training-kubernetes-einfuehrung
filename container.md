# Container

```
- vereint in sich Software
- Bibliotheken 
- Tools 
- Konfigurationsdateien 
- keinen eigenen Kernel 
- gut zum Ausführen von Anwendungen auf verschiedenen Umgebungen 

- Container sind entkoppelt
- Container sind voneinander unabhängig 
- Können über wohldefinierte Kommunikationskanäle untereinander Informationen austauschen

- Durch Entkopplung von Containern:
  o Unverträglichkeiten von Bibliotheken, Tools oder Datenbank können umgangen werden, wenn diese von den Applikationen in unterschiedlichen Versionen benötigt werden.
```


## Anwendungsfälle 

  * Unterschiedliche Versionen einer Applikation (z.B. MariaDB-Server) auf einem Linux-System betreiben
  * Gute Skalieren zu können (Beispiel: Bestellanzahl steigt (wir brauchen bei Ressourchen für Shop-Katalog und Warenkorb), aber nicht für Registrierung
    * Sprachagnostik /ein Service in python, einer in Rust 
