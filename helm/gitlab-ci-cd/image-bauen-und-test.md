# GitLab CI/CD - Docker Image bauen und in Registry pushen

## Ziel

  * Ein Docker-Image mit GitLab CI/CD automatisch bauen
  * Das Image in die GitLab Container Registry pushen

## Schritt 1: Referenzprojekt importieren

```
# In GitLab einloggen, dann:
https://gitlab.com/projects/new#import_project
```

```
# Folgende URL als Import-Quelle angeben:
https://gitlab.com/jmetzger/training-build-test-ci-cd-gitlab.git
```

```
# Einen eigenen Projektnamen vergeben
# Visibility: public
```

## Schritt 2: Pipeline anschauen

  * Im Projekt: **CI/CD -> Pipeline editor** öffnen
  * Die Datei `.gitlab-ci.yml` enthält den Build-Job

## Schritt 3: Pipeline ausführen

  * Unter **CI/CD -> Pipelines** die laufende Pipeline beobachten
  * Nach erfolgreichem Lauf: **Deploy -> Container Registry** prüfen
  * Das gebaute Image ist dort sichtbar

## Schritt 4: Eigene Änderung triggern

```
# Eine kleine Änderung an einer Datei vornehmen (z.B. index.html)
# und committen -> Pipeline startet automatisch
```

## Referenz

  * Beispielprojekt (public): https://gitlab.com/jmetzger/training-build-test-ci-cd-gitlab
