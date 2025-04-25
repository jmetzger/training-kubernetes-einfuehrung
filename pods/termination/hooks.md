# How to increase time before stopping a pod

When stopping (terminating) a pod in Kubernetes, there **are hooks available**, but they're limited to the **termination lifecycle**. If you're thinking of stopping a pod *without* killing it and still triggering hooks, that's trickier (more on that below). Here's a full breakdown of what's available:

---

## ✅ **Kubernetes Hooks for Pod Termination**

### 1. **`preStop` Hook**
Executed **before the container is terminated** (but *after* the SIGTERM signal is sent).

#### Example:
```yaml
lifecycle:
  preStop:
    exec:
      command: ["/bin/sh", "-c", "echo pre-stop hook running; sleep 10"]
```

- You can use this to delay shutdown or do cleanup.
- Note: Kubernetes still sends `SIGTERM` as normal; `preStop` doesn't block that, but the container stays up for the duration of the hook.

---

### 2. **`terminationGracePeriodSeconds`**
Specifies how long Kubernetes will wait before force-killing the container with `SIGKILL`.

```yaml
spec:
  terminationGracePeriodSeconds: 30
```

- Combine this with `preStop` to allow your container to finish in-flight work or deregister from a service.


If you tell me **what kind of "stop" you're envisioning**, I can help tailor a hook-like workaround. For example:  
→ *“I want to stop background work when CPU is high”* or  
→ *“Pause processing until a Kafka topic is ready”* — totally different tactics.

