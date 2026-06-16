# Chart runterladen und evtl entpacken (auch bestimmte version) 

```
cd 
mkdir -p charts-download
cd charts-download
```


```
# Lädt die letzte version herunter
helm pull oci://registry-1.docker.io/cloudpirates/mariadb

# Lädt bestimmte chart-version runter 
# helm pull oci://registry-1.docker.io/cloudpirates/mariadb --version 0.9.0
# evtl. entpacken wenn gewünscht
# tar xvf mariadb-12.1.6.tgz

# Schnelle Variante
helm pull oci://registry-1.docker.io/cloudpirates/mariadb --version 0.9.0 --untar
```
