# Verwaltung in Docker 

  * Unser System wird über docker ausgerollt

## Wie greife ich drau zu  ? 

  1. per ssh einloggen
  1. docker exec -it monitoring bash


Danach müssen auf unsere Installation zugreifen

```
omd sites
```

<img width="800" height="99" alt="image" src="https://github.com/user-attachments/assets/de3f13a0-aa66-4a59-9874-71238ac65c83" />

```
# in unserem Fall dann in die instanz wechseln mit:
# um auf die dortige Shell zu wechseln 
omd su cmk
```
