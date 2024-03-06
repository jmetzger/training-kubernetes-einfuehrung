# CSI 

```
11.1 Why CSI 

Each vendor can create his own driver for his storage 

11.2 Advantages:

I. Automatically create storage when required.
II. Make storage available to containers wherever they’re scheduled.
III. Automatically delete the storage when no longer needed. 

11.3 Before 

Vendor needed to wait till his code was checked in in tree of kubernetes.

11.3.5. Unterschied statisch, dynamisch.

The main difference relies on the moment when you want to configure storage. For instance, if you need to pre-populate data in a volume, you choose static provisioning. Whereas, if you need to create volumes on demand, you go for dynamic provisioning.

```
