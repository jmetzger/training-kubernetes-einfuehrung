# Helm - Grundlagen

## Wo kann ich Helm-Charts suchen ? 

 * Im Telefonbuch von helm [https://artifacthub.io/](https://artifacthub.io)

## Komponenten 

### Chart

  * beeinhaltet Beschreibung und Komponenten 

### Chart-Formate 

  * url
  * .tgz (abkürzung tar.gz) - Format 
  * oder Verzeichnis 

```
Wenn wir ein Chart ausführen wird eine Release erstellen 
(parallel: image -> container, analog: chart -> release)
```

## Installation 

```
# Beispiel ubuntu 
# snap install --classic helm

# Cluster auf das ich zugreifen kann und im client -> helm und kubectl 
# Voraussetzung auf dem Client-Rechner (helm ist nichts als anderes als ein Client-Programm) 
Ein lauffähiges kubectl auf dem lokalen System (welches sich mit dem Cluster verbinden.
-> saubere -> .kube/config 

# Test
kubectl cluster-info 

```

