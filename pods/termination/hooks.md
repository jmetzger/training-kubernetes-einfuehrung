# Termination Hooks 

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

---

## 🚫 No Hook for "Pausing" a Pod
There is **no lifecycle hook** for when a pod is paused (e.g., marked `NotReady` or manually paused via the runtime).

If you're trying to:

- Stop processing
- Wait for an event
- Delay termination for a custom reason

...then the best you can do is **fake a "pause" using readiness probes** or a custom controller.

---

## ⚡ Advanced Alternatives
If you're looking for **"hooks" based on events other than termination**, consider:

### 🔹 Using a **Readiness Probe** + internal logic
Your app goes into "standby mode" and reports `NotReady`:
- This triggers the pod to stop receiving traffic.
- Your app still runs but isn't considered healthy.

### 🔹 Using **Finalizers** (for custom resource cleanup)
If you're working with custom resources or controllers:
- Finalizers let you **delay deletion** until cleanup is done.
- Not for regular pods — but useful in operator logic.

---

## Summary

| Action                        | Native Hook? | Notes |
|-----------------------------|--------------|-------|
| Pod termination (SIGTERM)   | ✅ `preStop`  | Great for cleanup before shutdown |
| Pod pause / standby         | ❌ No         | Simulate via readiness probes |
| Pod deletion delay          | ✅ grace period, finalizers | For graceful shutdown or CRD cleanup |
| Pod start / postStart       | ✅ `postStart`| Only runs at container startup |

---

If you tell me **what kind of "stop" you're envisioning**, I can help tailor a hook-like workaround. For example:  
→ *“I want to stop background work when CPU is high”* or  
→ *“Pause processing until a Kafka topic is ready”* — totally different tactics.

