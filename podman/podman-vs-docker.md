# Podman vs. Docker 
---

## Was ist Podman?

**Podman** (kurz für: *Pod Manager*) ist eine Open-Source-Container-Engine, die als Alternative zu Docker entwickelt wurde.

---

## Warum Podman?

Hier die wichtigsten Gründe, warum Podman gerne verwendet wird:

| Vorteil                                         | Erklärung                                                                                                                                                                 |
| ----------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Daemonless**                                  | Podman benötigt keinen zentralen Hintergrunddienst (Daemon), sondern läuft als normaler Benutzerprozess. Dadurch weniger Angriffsfläche und flexibler.                    |
| **Rootless Support**                            | Container können ohne Root-Rechte gestartet werden, was Sicherheitsvorteile bringt.                                                                                       |
| **Docker-kompatibel**                           | Podman kann Dockerfiles bauen und verwendet dieselben Container Images. Auch `podman` CLI ist zu `docker` CLI fast identisch (`alias docker=podman` geht oft problemlos). |
| **Pods-Unterstützung**                          | Inspiriert von Kubernetes: Mehrere Container in einem gemeinsamen Netzwerk-Namespace (Pod). Praktisch für lokale Kubernetes-ähnliche Setups.                              |
| **Bessere Integration für Systemd**             | Einfaches Erstellen von Systemd-Units aus Containern (`podman generate systemd`). Ideal für Serverdienste ohne externes Orchestration-Tool.                               |
| **Kein Root-Daemon**                            | Keine ständigen Root-Rechte nötig, weniger Sicherheitsrisiko durch kompromittierte Daemons.                                                                               |
| **Red Hat / Fedora / CentOS bevorzugen Podman** | Dort wird Podman inzwischen oft als Standardlösung ausgeliefert.                                                                                                          |

---

## Typische Einsatzbereiche

* Entwicklung: wie Docker
* Serverbetrieb: Container als Systemdienste
* Kubernetes-nahes Testing (Pods)
* Rootless Deployment auf Servern ohne Container-Daemon

---

## Beispiel: Container starten

```bash
podman run -d -p 8080:80 nginx
```

Fast wie bei Docker.

---

## Podman vs Docker kurz gesagt:

|                     | Docker     | Podman            |
| ------------------- | ---------- | ----------------- |
| Daemon              | ja         | nein              |
| Rootless            | begrenzt   | ja                |
| Kubernetes-nah      | weniger    | stärker           |
| Systemd-Integration | wenig      | stark             |
| Kompatibilität      | verbreitet | Docker-kompatibel |

---

Wenn du magst, kann ich dir noch:

* **ein kleines Podman-Lab-Skript**
* **ein Vergleichsszenario Podman vs Docker**
* **eine Rootless-Setup-Anleitung**
* **oder sogar ein Kubernetes-nahes Podman-Pod-Beispiel**

zusammenstellen.
👉 *Was davon interessiert dich?*
