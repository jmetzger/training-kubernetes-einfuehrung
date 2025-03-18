# Garbage Collection Events Kubernetes 

## Overview 

In Kubernetes, events are stored in **etcd**, which is the key-value store used by Kubernetes for cluster state. However, events in etcd are not cleaned up automatically by Kubernetes or the API server. The Kubernetes API server itself does not handle the direct cleanup of events from etcd, and the process of cleaning up events is handled by a combination of **TTL (Time-to-Live)** settings and background jobs, like **Event Garbage Collection**.

Here's a breakdown of how event cleanup works:

### 1. **Event TTL (Time-to-Live)**
   - Kubernetes events have a **default TTL** (time-to-live) associated with them. This TTL is typically **1 hour** by default.
   - Once the event reaches its TTL, it becomes eligible for deletion.
   - The TTL is set when the event is created and is stored alongside the event object in etcd.

### 2. **Event Garbage Collection**
   - Kubernetes uses a **garbage collector** process to clean up events from the etcd store after they exceed their TTL.
   - The actual cleanup of expired events happens through **event garbage collection**, which runs periodically.
   - The default TTL for events can be configured via the API server’s flags (`--event-ttl`), and it’s commonly set to 1 hour.
   - The garbage collection process is part of the **Kubernetes controller manager**, not directly the API server. The controller manager is responsible for various background tasks, including cleaning up events.

### 3. **Event Storage and Expiration**
   - When an event reaches its TTL, the garbage collection process marks the event for deletion from the etcd store.
   - If the TTL is exceeded, the event is **deleted** by Kubernetes automatically.

### 4. **Custom TTL for Events**
   - Administrators can customize the TTL for events based on their requirements. This can be done by setting the `--event-ttl` flag on the Kubernetes API server.
   - For example, if you set `--event-ttl=30m`, events will be kept in etcd for only 30 minutes.

### To summarize:
   - The **Kubernetes API server** does not directly clean up events in etcd. 
   - The **controller manager** is responsible for the **garbage collection** of events after their TTL expires.
   - Events are automatically cleaned up based on their TTL configuration, but this behavior can be customized through the `--event-ttl` flag.

If you're facing issues with event cleanup, you can check the TTL configuration or monitor the controller manager logs for any errors related to event garbage collection.
