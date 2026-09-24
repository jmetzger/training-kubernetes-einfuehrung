# function irate()

### ⚡ `irate()`: **Sofortiger (instantaner) Anstieg**

* **Verwendet nur die letzten zwei Datenpunkte** im Intervall.
* Gibt die „momentane“ Rate zum Zeitpunkt des Queries zurück.
* Ideal für **Alerts**, bei denen eine **schnelle Reaktion** auf Lastspitzen nötig ist.

```promql
irate(http_requests_total[5m])
```

### Vergleich:

| Funktion  | Typ          | Verwendet Samples | Verwendung             |
| --------- | ------------ | ----------------- | ---------------------- |
| `rate()`  | Durchschnitt | Alle im Intervall | Graphen, Trends        |
| `irate()` | Sofortwert   | Nur die letzten 2 | Alarme, Peak-Erkennung |

---

### Beispiel in der Praxis:

* Du hast ein Scrape-Intervall von 15 s.
* Dann nutzt `rate(http_requests_total[1m])` **4 Messpunkte**.
* `irate(http_requests_total[1m])` nutzt **nur die letzten beiden**.
