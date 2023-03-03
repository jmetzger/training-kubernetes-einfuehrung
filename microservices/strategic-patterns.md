# Strategic Patterns 

## Pattern: Strangler Fig Application 

  * Technik zum Umschreiben von Systemen 

### Wie umleitung, z.B.

  * http proxy 
  * oder s.u. branch by extraction
  * An- und Abschalten mit Feature Toggle 
  * Über message broker 

### http - proxy - Schritte 

  1. Schritt: Proxy einfügen
  2. Schritt: Funktionalität migrieren 
  3. Schritt: Aufrufe umleiten

### Message broker

  * Monolith reagiert auf bestimmte Messages bzw. ignoriert bestimmte messages
  * monolith bekommt bestimmte nachrichten garnicht 
  * service reagiert auf bestimmte nachrichten 


## Pattern: Parallel Run 

  * Service und Teil im Monolith wird parallel ausgeführt
  * Und es wird überprüft, ob das Ergebnis in beiden Systemn das gleiche ist (z.B. per batch job)

## Pattern: Decorating Collaborator

  * Ansteuerung als nachgelagerten Prozess über einen Proxy 

## Pattern Branch by Abstraction 

  * Beispiel Notification 

### Schritt 1: Abstraction der zu ersetzendne Funktionalität erstellen


### Schritt 2: Ändern sie die Clients der bestehenden Funktionalität so, dass sie die neue Abstraktion verwenden


### Schritt 3: Neue Implementierung der Abstraktion 

```
Erstellen Sie eine neue Implementierung der Abstraktion mit der 
überarbeiteten Funktionalität. 

In unserem Fall wird diese neue Implementierung unseren neuen 
Mikroservice aufrufen
```

### Schritt 4: Abstraktion anpassen -> neue Implementierung

```
Abstraktion anpassen, dass sie unsere neue Implementierung verwendet
```

### Schritt 5: Abstraktion aufräumen und alte Implementierung entfernen 


