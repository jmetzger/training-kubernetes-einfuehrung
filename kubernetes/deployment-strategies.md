# Deployment (Canary, A/B-Deployment, Blue-/Green-Deployment) 
  
```
10.1 Canary

Eine kleine Teilmenge der Nutzer bekommt die neue Anwendung zu sehen, 
der Rest immer noch die alte.
Es funktioniert als Testballon 



10.2. Blue / Green

aktuelle Version ist Blue
neue Green 

Neue wird getestet, und wenn sie funktioniert wird der Traffic von Blue auf Green umgeschwitzt.
Blue kann entweder gelöscht werden oder dient als Fallback

10.3. A/B 

Es sind zwei verschiedene Versionen online, um bspw. etwas zu testen.
(Neues Feature) 

Dabei kann man die Gewichtung entsprechend durch Anzahl der jeweiligen Pods
im jeweiligen Deployment konfigurieren.
z.B. Deployment1: 10 pods
Deployment2: 5 pods

Beide haben ein gemeinsames Label. 

Über dieses Label greift der Service darauf zu.

```
