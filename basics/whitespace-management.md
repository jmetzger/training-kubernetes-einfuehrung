# Whitespace-Kontrolle

## Grundlagen 

  * In Helm (bzw. in Go-Templates) hast du verschiedene Möglichkeiten, den Umgang mit Whitespace (z. B. Leerzeichen, Zeilenumbrüche) zu steuern:

- `{{ ... }}`:  
  Standardvariante. Lässt den Whitespace außerhalb der geschweiften Klammern unverändert.

- `{{- ... }}`:  
  Entfernt den Whitespace links (vor) dem Ausdruck und AUCH die Zeilenmbrüche davor 

- `{{ ... -}}`:  
  Entfernt den Whitespace rechts (nach) dem Ausdruck, aber AUCH Zeilenumbrüche 

- `{{- ... -}}`:  
  Entfernt Whitespace sowohl links als auch rechts des Ausdrucks, aber AUCH Zeilenumbrüche 

