# irate() vs. rate()

## Vergleich

  * irate nimmt nur die letzten beiden Werte
  * rate bezieht alle Werte mit ein.

## Wann ist irate() sinnvoll (für:) ?

  * Alarme, bei denen du schnell auf Spikes reagieren willst.
  * Wenn du den aktuellsten Ausschlag brauchst (z. B. Lastspitzen, Traffic-Peaks).

## Wann ist rate() sinnvoll

  * Dashboards, bei denen Stabilität und Trends im Vordergrund stehen.
  * Beispiel: Traffic, CPU-Auslastung, Request-Rate über längere Zeiträume.

![image](https://github.com/user-attachments/assets/f4ecc4a0-758e-4997-be73-0f0302bc65d2)

Im Diagramm siehst du deutlich:

* **`rate()` (blau)** ist geglättet und zeigt einen stabileren Verlauf – gut für Trends.
* **`irate()` (orange gestrichelt)** reagiert stärker auf kurzfristige Schwankungen – gut für Alarme.
* Die graue Linie zeigt den tatsächlichen Rohwertwechsel pro Sekunde.
