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

  * Im Projekt: **Build -> Pipeline editor** öffnen
  * Die Datei `.gitlab-ci.yml` enthält den Build-Job

## Schritt 3: Pipeline ausführen

  * Unter **Build -> Pipelines** -> **Run pipeline** -> Branch: **master** -> **Run pipeline**
  * Die Pipeline beobachten (3 Jobs: build, test, code_quality)
  * Nach erfolgreichem Lauf: **Deploy -> Container Registry** prüfen
  * Das gebaute Image ist dort sichtbar (Tag = Commit-Hash)

## Schritt 4: Eigene Änderung triggern

```
# Hinweis: Das Repo verwendet "master" als default Branch (nicht "main")

# Eine kleine Änderung an einer Datei vornehmen (z.B. index.js)
# und committen -> Pipeline startet automatisch
```

## Referenz

  * Beispielprojekt (public): https://gitlab.com/jmetzger/training-build-test-ci-cd-gitlab
