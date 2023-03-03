# Wie schneidet man einen Monolithen (zu microservices) 

## Wie kann ich schneiden (NOT's) ? 

  * Code-Größe 
  * Technische Schnitt 
  * Amazon: 2 Pizzas, wieviele können sich davon, wei gross kann man team 
  * Microserver wegschmeissen und er müsste in wenigen Tagen oder mehreren Wochen wieder herstellen

## Wie kann ich schneiden (GUT) ? 

  * DDD (Domain Driven Design) - Welche Aufgaben gibt es innerhalb des sogenannten Bounded Context in meiner Domäne 
  * Domäne: Bibliothek 
  * In der Bibliothek 
    * Leihe 
    * Suche 

## Bounded Context 

![Bounded Context](https://martinfowler.com/bliki/images/boundedContext/sketch.png)

## Zwei Merkmale mit den wir arbeiten

  * Kohäsion (innerer Zusammenhalt des Fachbereichs) - innerhalb eines Services  
  * Bindung (lose Bindung) - zwischen den Services 
  * Jeder Service soll unabhängig sein 

## Was heisst unabhängiger Service 
  
  1. Er muss funktionieren, auch wenn ein anderes Service nicht läuft (keine Abhängigkeit) 
  2. Er darf nicht DIREKT auf die Daten eines anderen Services zugreifen (maximal über Schnittstelle)
  3. Jeder hat Service, ist völlig autark und seine eigene BusinessLogik und seine eigene Datenbank 

## Regeln für das Design von Services 

### Regel 1:

```
Es sollte eine große Kohäsion innerhalb des Services sein.
(Bindung). Alles sollte möglichst benötigt werden.

(Ist eine schwache Kohäsion innerhalb des Services, sind Funktionen 
dort, die eigentlich in einen anderen Service gehören)
```

### Regel 2: lose Bindung (zwischen Services) 

```
Es sollte eine lose Bindung zu anderen Services geben.
(Ist die Bindung zu gross, sind entweder die Services zu klein konzipiert
oder Funktionen sind an der falschen Stelle implementiert) 

zu klein: zu viele Abfragen anderer Service .... 

````

### Regel 3: unabhängigkeit 

```
Jeder Service muss eigenständig sein und seine eigene Datenbank haben.
```

## Datenbanken 

### Herangehensweise

```
heisst auch: 
o Kein großes allmächtiges Datenmodel, sondern viele kleine 
(nicht alles in jedem kleinen Datenmodel, sondern nur, was im jeweiligen
Bounded Context benötigt wird)
```

### Eine Datenbank pro Service (eigenständig / abgespeckt) 


#### Warum ?

```
Axiom: Eine eigenständige Datenbank pro Service. Warum ? 
(Service will NEVER reach into another services database)
```

#### Punkt 1 : Jeder Service soll unabhängig laufen können 

```
We want earch service to run independently of other services 

o no DB for everything (If DB goes down our service goes down)
o it easier to scale (if one service needs more capacity)
o more resilient. If one service goes down, our service will still work.
```

### Punkt 2: Datenbank schemata könnten sich unerwartet ändern 

```
o We (Service A) use data from Service B, directly retrieving it from the db.
o We (Service) want property name: Lisa
o Team of Service B changes this property to: firstName 
  AND do not inform us.
  (This breaks our service !!) . OUR SERV
```

### Punkt 3: Freiheit der Datenbankwahl 

```
3.4.3 Some services might funtion more efficiently with different types
of DB's (sql vs. nosql)
```


## Beispiel - Bounded 

```
Der Bounded Context definiert den Einsatzbereich eines Domänenmodells. 
```

```
Es umfasst die Geschäftslogik für eine bestimmte Fachlichkeit. Als Beispiel beschreibt ein Domänenmodell 
die Buchung von S-Bahn-Fahrkarten 
und ein weiteres die Suche nach S-Bahn-Verbindungen. 
```

```
Da die beiden Fachlichkeiten wenig miteinander zu tun haben, 
sind es zwei getrennte Modelle. Für die Fahrkarten sind die Tarife relevant und für die Verbindung die Zeit, das Fahrziel und der Startpunkt der Reise.
```

```
oder z.B. die Domäne: Bibliothek 
Bibliothek 
  Leihe (bounded context 1)
  Suche (bounded context 2)
```


