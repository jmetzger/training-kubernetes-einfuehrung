# Terminierung von Containern vermeiden, wenn Script läuft:

  * https://kubernetes.io/docs/concepts/containers/container-lifecycle-hooks/


```
preStop - Hook 

Prozess läuft wie folgt:

 

Timeout before runterskalierung erfolgt ?
Was ist, wenn er noch rechnet ? (task läuft, der nicht beendet werden soll) 

Timeout: 30 sec.
preStop 

This is the process.

a. State of pod is set to terminate 
b. preStop hook is executed, either exec or http
after success.
c. Terminate - Signal is sent to pod/container
d. Wait 30 secs.
e. Kill - Signal is set, if container did stop yet.
```

