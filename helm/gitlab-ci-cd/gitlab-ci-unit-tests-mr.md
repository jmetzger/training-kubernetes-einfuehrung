# Uebung: Unit Tests im GitLab Merge Request Dashboard

## Hintergrund

GitLab kann Test-Ergebnisse direkt im **Merge Request Dashboard** anzeigen —
ohne in die Job-Logs schauen zu muessen.

Dazu speichert der CI-Job einen JUnit-XML-Report als Artifact:

```
artifacts:
  when: always          # auch bei fehlgeschlagenen Tests hochladen!
  reports:
    junit: report.xml
```

GitLab vergleicht automatisch den Test-Status von Feature-Branch und Ziel-Branch
und hebt neu fehlgeschlagene oder geloeste Tests hervor.

Funktioniert auf allen GitLab-Tiers (Free, Premium, Ultimate).

## Schritt 1: Auf GitLab einloggen

```
https://gitlab.com

Account:  training.tn<X>     (X = deine Teilnehmernummer, z.B. training.tn2)
Passwort: vom Trainer
```

## Schritt 2: Demo-Repo forken

```
1. https://gitlab.com/jmetzger/training-gitlab-ci-tests aufrufen

2. Oben rechts: "Fork" klicken

3. Im Fork-Dialog:
   - Namespace: training.tn<X>   (euer gemeinsamer Account)
   - Project name: training-ci-tests-<dein-name>
     (z.B. training-ci-tests-anna — eindeutig, da ihr den Account teilt!)
   - Visibility: Public

4. "Fork project" klicken
```

## Schritt 3: Pipeline auf main-Branch pruefen

```
1. Im geforkten Repo: CI/CD -> Pipelines

2. Es laeuft automatisch eine Pipeline auf main

3. Job "unit-tests" anklicken
```

Erwartete Ausgabe im Job-Log:

```
10 passed in 0.03s
```

Alle Tests gruen — der Ausgangszustand ist sauber.

## Schritt 4: Feature-Branch mit Bug erstellen

Im Web-Editor (kein lokales Git noetig):

```
1. Im Repo links: "Code" -> "<> Repository"

2. Datei "calculator.py" anklicken

3. Oben rechts: "Edit" -> "Edit single file"

4. Zeile 15 aendern:

   VORHER:
   def is_even(n):
       return n % 2 == 0

   NACHHER (Bug einbauen):
   def is_even(n):
       return n % 2 != 0  # BUG

5. Unten bei "Commit changes":
   - Commit message: "Add is_even feature - WIP"
   - Haekchen bei "Create a new branch"
   - Branch name: feature/is-even-<dein-name>
     (z.B. feature/is-even-anna)
   - "Commit changes" klicken
```

## Schritt 5: Merge Request erstellen

```
1. GitLab zeigt oben einen blauen Banner:
   "Create merge request"

2. Klick darauf

3. Im MR-Formular:
   - Title: "Fix is_even - <dein-name>"
   - Source branch: feature/is-even-<dein-name>
   - Target branch: main

4. "Create merge request" klicken
```

## Schritt 6: Test-Ergebnisse im MR Dashboard beobachten

Die Pipeline laeuft jetzt auf dem Feature-Branch.
Sobald sie fertig ist (ca. 1-2 Minuten), erscheint im MR:

```
Test summary
  2 newly failed tests

  test_calculator > test_is_even_true
  test_calculator > test_is_even_false
```

**Erwartetes Verhalten:** Pipeline-Status rot, 2 neu fehlgeschlagene Tests sichtbar.

Auf einen Test klicken zeigt den genauen Fehler:

```
assert False is True
 +  where False = is_even(4)
```

## Schritt 7: Bug fixen

```
1. Im MR oben: "Code" -> "Open in Web IDE"
   (oder zurueck zur Datei: Code -> calculator.py -> Edit)

2. Zeile 15 zurueck auf:

   def is_even(n):
       return n % 2 == 0

3. Commit message: "Fix is_even: correct comparison operator"

4. Commit auf denselben Feature-Branch
```

## Schritt 8: Tests werden gruen

Pipeline laeuft erneut. Im MR erscheint jetzt:

```
Test summary
  2 fixed tests

  test_calculator > test_is_even_true   (fixed)
  test_calculator > test_is_even_false  (fixed)
```

Pipeline-Status: gruen.

## Schritt 9: Merge Request mergen

```
1. "Merge" klicken

2. "Delete source branch" anhaeken (optional)

3. Bestaetigen
```

## Zusammenfassung

| Schritt | Was im MR-Dashboard erscheint |
|---------|-------------------------------|
| Feature-Branch mit Bug | 2 newly failed tests (rot) |
| Bug gefixt, neuer Commit | 2 fixed tests (gruen) |
| Alle Tests gruен | Pipeline gruen, Merge moeglich |

## Aufraeumen

```
Settings -> General -> Advanced -> Delete project
```
