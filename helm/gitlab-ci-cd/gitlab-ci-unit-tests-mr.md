# Uebung: Unit Tests in GitLab CI/CD und Merge Request Dashboard

## Hintergrund

GitLab kann Test-Ergebnisse direkt im **Merge Request Dashboard** anzeigen.
Dazu muss der CI-Job einen JUnit-XML-Report als Artifact speichern.
GitLab vergleicht dann den Test-Status von Feature-Branch und Ziel-Branch
und zeigt neu fehlgeschlagene oder geloeste Tests an.

Das funktioniert auf allen GitLab-Tiers (Free, Premium, Ultimate).

## Was wir bauen

```
calculator.py         <- Python-Funktionen
test_calculator.py    <- pytest-Tests
.gitlab-ci.yml        <- Pipeline mit JUnit-Artifact
```

Die Pipeline:

```
stages:
  - test

unit-tests:
  stage: test
  image: python:3.11-slim
  script:
    - pip install -r requirements.txt --quiet
    - pytest test_calculator.py -v --junitxml=report.xml
  artifacts:
    when: always
    reports:
      junit: report.xml
```

`when: always` ist wichtig — das Artifact wird auch bei fehlgeschlagenen Tests hochgeladen,
damit GitLab die Fehler im MR-Dashboard anzeigen kann.

## Schritt 1: Demo-Repo nach GitLab importieren

```
1. https://gitlab.com -> New project -> Import project -> Repository by URL

2. Git repository URL:
   https://github.com/jmetzger/training-gitlab-ci-tests.git

3. Project name: training-gitlab-ci-tests
4. Visibility: Private (oder Public)
5. Create project
```

## Schritt 2: Pipeline auf main-Branch pruefen

```
1. Im Repo: CI/CD -> Pipelines
2. Die Pipeline auf main laeuft automatisch
3. Job "unit-tests" -> alle 10 Tests sollen gruен sein
```

Erwartete Ausgabe im Job-Log:

```
10 passed in 0.03s
```

## Schritt 3: Feature-Branch mit Bug erstellen

Im GitLab Web-Editor oder lokal:

```
git clone https://gitlab.com/<dein-name>/training-gitlab-ci-tests.git
cd training-gitlab-ci-tests
git checkout -b feature/is-even-fix
```

Datei `calculator.py` oeffnen und den Bug einbauen — `is_even` Zeile aendern:

```
# vi calculator.py
```

Zeile 15 von:

```
def is_even(n):
    return n % 2 == 0
```

zu (Bug: Logik umgekehrt):

```
def is_even(n):
    return n % 2 != 0  # BUG
```

```
git add calculator.py
git commit -m "Add is_even feature - WIP"
git push origin feature/is-even-fix
```

## Schritt 4: Merge Request erstellen

```
1. GitLab zeigt oben einen Banner: "Create merge request"
2. Klick darauf
3. Title: "Fix is_even function"
4. Create merge request
```

## Schritt 5: Test-Ergebnisse im MR Dashboard beobachten

Sobald die Pipeline durchgelaufen ist, erscheint im Merge Request:

```
Test summary
  2 newly failed tests
  - test_calculator::test_is_even_true
  - test_calculator::test_is_even_false
```

**Erwartetes Verhalten:** Die Pipeline schlaegt fehl, da 2 Tests FAILED sind.
Das Dashboard zeigt genau welche Tests neu fehlschlagen.

## Schritt 6: Bug fixen und Tests zum Gruenen bringen

```
# vi calculator.py
```

Zeile 15 zurueck auf:

```
def is_even(n):
    return n % 2 == 0
```

```
git add calculator.py
git commit -m "Fix is_even: correct comparison operator"
git push origin feature/is-even-fix
```

Sobald die Pipeline erneut laeuft:

```
Test summary
  2 resolved tests
  - test_calculator::test_is_even_true
  - test_calculator::test_is_even_false

All 10 tests passed
```

## Schritt 7: Merge Request mergen

```
1. "Merge" klicken
2. Branch loeschen (optional)
```

## Zusammenfassung

| Schritt | Was GitLab anzeigt |
|---------|-------------------|
| Feature-Branch mit Bug | 2 newly failed tests (rot) |
| Bug gefixt | 2 resolved tests (gruen) |
| Alle Tests gruен | Pipeline gruen, MR kann gemergt werden |

## Aufraeumen

```
# Repo loeschen wenn nicht mehr benoetigt
Settings -> General -> Advanced -> Delete project
```
