# CSI 

## Grafik 

<img width="1052" height="590" alt="image" src="https://github.com/user-attachments/assets/58ce725e-59b0-4a71-849e-3520a4eae7bb" />



## Überblick 

### Warum CSI ?

  * Each vendor can create his own driver for his storage 

### Vorteile ? 

```
I. Automatically create storage when required.
II. Make storage available to containers wherever they’re scheduled.
III. Automatically delete the storage when no longer needed. 
```

### Wie war es vorher ?

```
Vendor needed to wait till his code was checked in in tree of kubernetes (in-tree)
```

### Unterschied static vs. dynamisch 

```
The main difference relies on the moment when you want to configure storage. For instance, if you need to pre-populate data in a volume, you choose static provisioning. Whereas, if you need to create volumes on demand, you go for dynamic provisioning.
```

## Komponenten 

### Treiber 

  * Für jede Storage Class (Storage Provider) muss es einen Treiber geben

### Storage Class 
