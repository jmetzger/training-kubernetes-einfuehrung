# Pod bleibt in Terminate 

Ein Pod hängt in Terminierung meist aus folgenden Gründen:

## Häufigste Ursachen:

**1. Graceful Shutdown Timeout**
- Container reagiert nicht auf SIGTERM
- Nach `terminationGracePeriodSeconds` (default 30s) wird SIGKILL gesendet
- Check: `kubectl describe pod <pod>` → Events

**2. Finalizers blockieren**
```bash
kubectl get pod <pod> -o yaml | grep finalizers -A 5
```
Manuelle Entfernung (Notfall):
```bash
kubectl patch pod <pod> -p '{"metadata":{"finalizers":null}}'
```

**3. PreStop Hook hängt**
- Zählt zur Grace Period
- Hook-Fehler blockiert Terminierung

**4. Volume Unmount Problem**
- Node kann Volume nicht freigeben
- Oft bei NFS/CSI-Storage

**5. Node NotReady**
- Kubelet antwortet nicht
- Pod bleibt in Terminating bis Node zurück oder nach ~5min force-deleted

## Quick Fix:
```bash
# Force delete (wenn nichts anderes hilft)
kubectl delete pod <pod> --grace-period=0 --force
```

**Debug-Befehle:**
```bash
kubectl get pod <pod> -o yaml
kubectl describe pod <pod>
kubectl logs <pod> --previous
```

## Was sind finalizer 

  * Finalizers sind Strings im metadata.finalizers-Array eines Pods, die verhindern, dass Kubernetes das Objekt vollständig löscht, bis alle Finalizer entfernt wurden.

```
Bei kubectl delete pod setzt Kubernetes nur metadata.deletionTimestamp
Pod geht in Status Terminating
Controller/Operator mit zuständigem Finalizer führt Cleanup aus
Controller entfernt seinen Finalizer aus dem Array
Erst wenn Array leer → vollständige Löschung
```

## Probleme mit Volumes 

**VolumeAttachment-Objekt** (separates K8s-Objekt):
```yaml
apiVersion: storage.k8s.io/v1
kind: VolumeAttachment
metadata:
  finalizers:
  - external-attacher/csi-driver-name  # <-- Hier ist der Finalizer
spec:
  attacher: csi-driver
  nodeName: worker-1
  source:
    persistentVolumeName: pvc-xyz
```

**Pod-Objekt** hat normalerweise **keine Volume-Finalizer**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  finalizers: []  # Meist leer oder mit anderen Finalizern
```

## Warum Pods trotzdem bei Volumes hängen:

1. **Kubelet wartet** auf erfolgreiches Volume-Unmount (nicht Finalizer-basiert)
2. **VolumeAttachment-Finalizer** verhindert Detach vom Node
3. **Node nicht erreichbar** → Kubelet kann nicht unmounten
4. **CSI-Driver-Probleme** → external-attacher kann Finalizer nicht clearen

## Typisches Problem-Szenario:

```bash
# Pod bleibt Terminating
kubectl get pod -o yaml
# deletionTimestamp gesetzt, aber keine Volume-Finalizer

# VolumeAttachment existiert noch
kubectl get volumeattachment
# Hat Finalizer vom CSI-Driver
```

**Force-Delete** hilft hier nicht beim Volume-Problem, sondern man muss das VolumeAttachment-Objekt oder den Node-Status addressieren.
