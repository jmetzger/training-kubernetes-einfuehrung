# Splunk vs. CheckMK vs. Prometheus/Grafana

## Tool-Vergleich auf einen Blick

<svg viewBox="0 0 700 320" xmlns="http://www.w3.org/2000/svg" style="max-width:700px">
  <!-- Hintergrund -->
  <rect width="700" height="320" fill="#1e1e2e" rx="12"/>

  <!-- Titel -->
  <text x="350" y="32" text-anchor="middle" fill="#cdd6f4" font-size="15" font-family="sans-serif" font-weight="bold">Monitoring Tools — Domain-Abdeckung</text>

  <!-- Spalten-Header -->
  <text x="140" y="60" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">Logs</text>
  <text x="270" y="60" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">Metriken</text>
  <text x="400" y="60" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">Infra-Checks</text>
  <text x="530" y="60" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">SIEM / Security</text>
  <text x="650" y="60" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">APM</text>

  <!-- Trennlinie -->
  <line x1="20" y1="68" x2="680" y2="68" stroke="#313244" stroke-width="1"/>

  <!-- === SPLUNK === -->
  <text x="70" y="105" text-anchor="middle" fill="#65ba44" font-size="13" font-family="sans-serif" font-weight="bold">Splunk</text>
  <text x="70" y="120" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">Enterprise</text>
  <!-- Logs: Kernkompetenz -->
  <rect x="90" y="88" width="100" height="36" rx="6" fill="#65ba44"/>
  <text x="140" y="111" text-anchor="middle" fill="#1e1e2e" font-size="11" font-family="sans-serif" font-weight="bold">Kernkompetenz</text>
  <!-- Metriken: moeglich -->
  <rect x="220" y="88" width="100" height="36" rx="6" fill="#65ba44" opacity="0.4"/>
  <text x="270" y="111" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">moeglich</text>
  <!-- Infra: nein -->
  <rect x="350" y="88" width="100" height="36" rx="6" fill="#313244"/>
  <text x="400" y="111" text-anchor="middle" fill="#585b70" font-size="11" font-family="sans-serif">—</text>
  <!-- SIEM: Kernkompetenz -->
  <rect x="480" y="88" width="100" height="36" rx="6" fill="#65ba44"/>
  <text x="530" y="111" text-anchor="middle" fill="#1e1e2e" font-size="11" font-family="sans-serif" font-weight="bold">Kernkompetenz</text>
  <!-- APM: ja -->
  <rect x="610" y="88" width="60" height="36" rx="6" fill="#65ba44" opacity="0.4"/>
  <text x="640" y="111" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">ja*</text>

  <!-- === PROMETHEUS/GRAFANA === -->
  <text x="70" y="155" text-anchor="middle" fill="#f5871f" font-size="12" font-family="sans-serif" font-weight="bold">Prometheus</text>
  <text x="70" y="169" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">+ Grafana</text>
  <!-- Logs: mit Loki -->
  <rect x="90" y="143" width="100" height="36" rx="6" fill="#f5871f" opacity="0.4"/>
  <text x="140" y="166" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">mit Loki</text>
  <!-- Metriken: Kernkompetenz -->
  <rect x="220" y="143" width="100" height="36" rx="6" fill="#f5871f"/>
  <text x="270" y="166" text-anchor="middle" fill="#1e1e2e" font-size="11" font-family="sans-serif" font-weight="bold">Kernkompetenz</text>
  <!-- Infra: begrenzt -->
  <rect x="350" y="143" width="100" height="36" rx="6" fill="#f5871f" opacity="0.4"/>
  <text x="400" y="166" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">begrenzt</text>
  <!-- SIEM: nein -->
  <rect x="480" y="143" width="100" height="36" rx="6" fill="#313244"/>
  <text x="530" y="166" text-anchor="middle" fill="#585b70" font-size="11" font-family="sans-serif">—</text>
  <!-- APM: mit Tempo -->
  <rect x="610" y="143" width="60" height="36" rx="6" fill="#f5871f" opacity="0.4"/>
  <text x="640" y="166" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">Tempo</text>

  <!-- === CHECKMK === -->
  <text x="70" y="205" text-anchor="middle" fill="#00b4aa" font-size="13" font-family="sans-serif" font-weight="bold">CheckMK</text>
  <!-- Logs: nein -->
  <rect x="90" y="198" width="100" height="36" rx="6" fill="#313244"/>
  <text x="140" y="221" text-anchor="middle" fill="#585b70" font-size="11" font-family="sans-serif">—</text>
  <!-- Metriken: ja -->
  <rect x="220" y="198" width="100" height="36" rx="6" fill="#00b4aa" opacity="0.4"/>
  <text x="270" y="221" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif">ja</text>
  <!-- Infra: Kernkompetenz -->
  <rect x="350" y="198" width="100" height="36" rx="6" fill="#00b4aa"/>
  <text x="400" y="221" text-anchor="middle" fill="#1e1e2e" font-size="11" font-family="sans-serif" font-weight="bold">Kernkompetenz</text>
  <!-- SIEM: nein -->
  <rect x="480" y="198" width="100" height="36" rx="6" fill="#313244"/>
  <text x="530" y="221" text-anchor="middle" fill="#585b70" font-size="11" font-family="sans-serif">—</text>
  <!-- APM: nein -->
  <rect x="610" y="198" width="60" height="36" rx="6" fill="#313244"/>
  <text x="640" y="221" text-anchor="middle" fill="#585b70" font-size="11" font-family="sans-serif">—</text>

  <!-- Legende -->
  <rect x="20" y="262" width="14" height="14" rx="3" fill="#65ba44"/>
  <text x="40" y="274" fill="#a6adc8" font-size="10" font-family="sans-serif">Kernkompetenz</text>
  <rect x="150" y="262" width="14" height="14" rx="3" fill="#65ba44" opacity="0.4"/>
  <text x="170" y="274" fill="#a6adc8" font-size="10" font-family="sans-serif">moeglich / teilweise</text>
  <rect x="310" y="262" width="14" height="14" rx="3" fill="#313244"/>
  <text x="330" y="274" fill="#a6adc8" font-size="10" font-family="sans-serif">nicht vorgesehen</text>
  <text x="20" y="300" fill="#585b70" font-size="9" font-family="sans-serif">* Splunk APM = zugekauftes Produkt (SignalFx)</text>
</svg>

---

## Splunk-Architektur

<svg viewBox="0 0 700 280" xmlns="http://www.w3.org/2000/svg" style="max-width:700px">
  <rect width="700" height="280" fill="#1e1e2e" rx="12"/>
  <text x="350" y="30" text-anchor="middle" fill="#cdd6f4" font-size="15" font-family="sans-serif" font-weight="bold">Splunk — Datenfluss</text>

  <!-- Datenquellen -->
  <text x="80" y="58" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">Datenquellen</text>

  <rect x="20" y="66" width="120" height="28" rx="5" fill="#313244"/>
  <text x="80" y="85" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">Kubernetes Logs</text>

  <rect x="20" y="102" width="120" height="28" rx="5" fill="#313244"/>
  <text x="80" y="121" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">App-Server</text>

  <rect x="20" y="138" width="120" height="28" rx="5" fill="#313244"/>
  <text x="80" y="157" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">Firewall / Network</text>

  <rect x="20" y="174" width="120" height="28" rx="5" fill="#313244"/>
  <text x="80" y="193" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">Windows / AD</text>

  <!-- Pfeile zu Forwarder -->
  <line x1="140" y1="80" x2="190" y2="130" stroke="#585b70" stroke-width="1.5" marker-end="url(#arr)"/>
  <line x1="140" y1="116" x2="190" y2="133" stroke="#585b70" stroke-width="1.5" marker-end="url(#arr)"/>
  <line x1="140" y1="152" x2="190" y2="138" stroke="#585b70" stroke-width="1.5" marker-end="url(#arr)"/>
  <line x1="140" y1="188" x2="190" y2="142" stroke="#585b70" stroke-width="1.5" marker-end="url(#arr)"/>

  <!-- Forwarder -->
  <rect x="190" y="110" width="110" height="50" rx="7" fill="#45475a"/>
  <text x="245" y="131" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif" font-weight="bold">Universal</text>
  <text x="245" y="148" text-anchor="middle" fill="#cdd6f4" font-size="11" font-family="sans-serif" font-weight="bold">Forwarder</text>
  <text x="245" y="175" text-anchor="middle" fill="#585b70" font-size="9" font-family="sans-serif">(Agent auf Host)</text>

  <!-- Pfeil zu Indexer -->
  <line x1="300" y1="135" x2="340" y2="135" stroke="#65ba44" stroke-width="2" marker-end="url(#arrg)"/>

  <!-- Indexer -->
  <rect x="340" y="100" width="110" height="70" rx="7" fill="#65ba44" opacity="0.2"/>
  <rect x="340" y="100" width="110" height="70" rx="7" fill="none" stroke="#65ba44" stroke-width="1.5"/>
  <text x="395" y="126" text-anchor="middle" fill="#65ba44" font-size="12" font-family="sans-serif" font-weight="bold">Indexer</text>
  <text x="395" y="143" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">komprimiert +</text>
  <text x="395" y="156" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">indiziert Daten</text>

  <!-- Pfeil zu Search Head -->
  <line x1="450" y1="135" x2="490" y2="135" stroke="#65ba44" stroke-width="2" marker-end="url(#arrg)"/>

  <!-- Search Head -->
  <rect x="490" y="100" width="110" height="70" rx="7" fill="#65ba44" opacity="0.2"/>
  <rect x="490" y="100" width="110" height="70" rx="7" fill="none" stroke="#65ba44" stroke-width="1.5"/>
  <text x="545" y="126" text-anchor="middle" fill="#65ba44" font-size="12" font-family="sans-serif" font-weight="bold">Search Head</text>
  <text x="545" y="143" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">SPL-Queries</text>
  <text x="545" y="156" text-anchor="middle" fill="#a6adc8" font-size="9" font-family="sans-serif">Web UI</text>

  <!-- Ausgaben -->
  <text x="630" y="58" text-anchor="middle" fill="#a6adc8" font-size="11" font-family="sans-serif">Ausgabe</text>

  <line x1="600" y1="115" x2="615" y2="75" stroke="#65ba44" stroke-width="1.5" marker-end="url(#arrg)"/>
  <rect x="615" y="62" width="75" height="24" rx="4" fill="#313244"/>
  <text x="652" y="78" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">Dashboards</text>

  <line x1="600" y1="135" x2="615" y2="135" stroke="#65ba44" stroke-width="1.5" marker-end="url(#arrg)"/>
  <rect x="615" y="123" width="75" height="24" rx="4" fill="#313244"/>
  <text x="652" y="139" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">Alerts</text>

  <line x1="600" y1="155" x2="615" y2="192" stroke="#65ba44" stroke-width="1.5" marker-end="url(#arrg)"/>
  <rect x="615" y="185" width="75" height="24" rx="4" fill="#313244"/>
  <text x="652" y="201" text-anchor="middle" fill="#cdd6f4" font-size="10" font-family="sans-serif">SIEM / SOC</text>

  <!-- SPL Label -->
  <text x="350" y="240" fill="#585b70" font-size="10" font-family="sans-serif">SPL = Search Processing Language  |  SOC = Security Operations Center</text>

  <!-- Pfeilmarker -->
  <defs>
    <marker id="arr" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#585b70"/>
    </marker>
    <marker id="arrg" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#65ba44"/>
    </marker>
  </defs>
</svg>

---

## Welches Tool fuer welche Frage?

<svg viewBox="0 0 700 340" xmlns="http://www.w3.org/2000/svg" style="max-width:700px">
  <rect width="700" height="340" fill="#1e1e2e" rx="12"/>
  <text x="350" y="30" text-anchor="middle" fill="#cdd6f4" font-size="15" font-family="sans-serif" font-weight="bold">Entscheidungshilfe</text>

  <!-- Fragen (links) -->
  <rect x="20" y="50" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="71" fill="#cdd6f4" font-size="11" font-family="sans-serif">Ist mein Server / Service up?</text>

  <rect x="20" y="95" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="116" fill="#cdd6f4" font-size="11" font-family="sans-serif">Wie hoch ist CPU / Memory / Request-Rate?</text>

  <rect x="20" y="140" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="161" fill="#cdd6f4" font-size="11" font-family="sans-serif">Was steht in den Logs bei Fehler X?</text>

  <rect x="20" y="185" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="206" fill="#cdd6f4" font-size="11" font-family="sans-serif">Wer hat wann was auf dem System gemacht?</text>

  <rect x="20" y="230" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="251" fill="#cdd6f4" font-size="11" font-family="sans-serif">Wurde ein Angriff durchgefuehrt? (SIEM)</text>

  <rect x="20" y="275" width="320" height="32" rx="6" fill="#313244"/>
  <text x="30" y="296" fill="#cdd6f4" font-size="11" font-family="sans-serif">Kubernetes Metriken + Autoscaling?</text>

  <!-- Pfeile -->
  <line x1="340" y1="66" x2="370" y2="66" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="340" y1="111" x2="370" y2="111" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="340" y1="156" x2="370" y2="156" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="340" y1="201" x2="370" y2="201" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="340" y1="246" x2="370" y2="246" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>
  <line x1="340" y1="291" x2="370" y2="291" stroke="#585b70" stroke-width="1.5" marker-end="url(#a2)"/>

  <!-- Antworten (rechts) -->
  <rect x="370" y="50" width="310" height="32" rx="6" fill="#00b4aa" opacity="0.25"/>
  <rect x="370" y="50" width="6" height="32" rx="3" fill="#00b4aa"/>
  <text x="386" y="71" fill="#00b4aa" font-size="12" font-family="sans-serif" font-weight="bold">CheckMK</text>

  <rect x="370" y="95" width="310" height="32" rx="6" fill="#f5871f" opacity="0.2"/>
  <rect x="370" y="95" width="6" height="32" rx="3" fill="#f5871f"/>
  <text x="386" y="116" fill="#f5871f" font-size="12" font-family="sans-serif" font-weight="bold">Prometheus / Grafana</text>

  <rect x="370" y="140" width="310" height="32" rx="6" fill="#65ba44" opacity="0.2"/>
  <rect x="370" y="140" width="6" height="32" rx="3" fill="#65ba44"/>
  <text x="386" y="161" fill="#65ba44" font-size="12" font-family="sans-serif" font-weight="bold">Splunk  oder  Grafana Loki</text>

  <rect x="370" y="185" width="310" height="32" rx="6" fill="#65ba44" opacity="0.2"/>
  <rect x="370" y="185" width="6" height="32" rx="3" fill="#65ba44"/>
  <text x="386" y="206" fill="#65ba44" font-size="12" font-family="sans-serif" font-weight="bold">Splunk  (Audit Log)</text>

  <rect x="370" y="230" width="310" height="32" rx="6" fill="#65ba44" opacity="0.2"/>
  <rect x="370" y="230" width="6" height="32" rx="3" fill="#65ba44"/>
  <text x="386" y="251" fill="#65ba44" font-size="12" font-family="sans-serif" font-weight="bold">Splunk  (SIEM / SOC)</text>

  <rect x="370" y="275" width="310" height="32" rx="6" fill="#f5871f" opacity="0.2"/>
  <rect x="370" y="275" width="6" height="32" rx="3" fill="#f5871f"/>
  <text x="386" y="296" fill="#f5871f" font-size="12" font-family="sans-serif" font-weight="bold">Prometheus / Grafana</text>

  <defs>
    <marker id="a2" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
      <path d="M0,0 L0,6 L8,3 z" fill="#585b70"/>
    </marker>
  </defs>
</svg>

---

## Splunk im Detail

### Was Splunk kann

**Log-Aggregation** — alle Logs zentral sammeln und in Echtzeit durchsuchen:

```
index=kubernetes namespace=production | stats count by pod_name | sort -count
```

**SIEM** (Security Information and Event Management):
- Korreliert Events aus verschiedenen Quellen (Firewall, AD, Kubernetes, App)
- Erkennt Angriffsmuster automatisch (Brute-Force, Lateral Movement)
- Compliance-Reporting (PCI-DSS, SOC2, ISO 27001)
- Incident Response — Timeline eines Angriffs rekonstruieren

**Splunk heute — mehr als Logs:**
- Splunk APM (Application Performance Monitoring, zugekauft via SignalFx)
- Splunk Infrastructure Monitoring
- Splunk Synthetic Monitoring

### Open-Source-Alternative: Grafana Loki

Fuer reines Log-Management in Kubernetes ist **Grafana Loki** oft ausreichend:
- Kostenlos, direkt in Grafana integriert
- Gleiche Idee wie Splunk (Logs sammeln + durchsuchen)
- Kein SIEM, aber fuer Entwickler-Use-Cases ideal

### Kosten

Splunk lizenziert nach **Datenvolumen pro Tag** — in grossen Umgebungen
einer der teuersten Posten im Monitoring-Budget.

| Einsatzbereich | Empfehlung |
|---|---|
| Kubernetes Dev/Staging | Grafana Loki (kostenlos) |
| Kubernetes Production | Grafana Loki oder Splunk |
| Enterprise + Compliance | Splunk |
| Security / SOC | Splunk |
