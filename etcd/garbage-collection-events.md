
# Who cleans up events in etc, kubernetes api server ?

## Overview 
No, the **Kubernetes API server does not directly clean up events in etcd**.  

### Who Cleans Up Events in etcd?
- **The Kubernetes controller manager** is responsible for cleaning up expired events, **not the API server**.  
- The **event garbage collection** process runs periodically to remove events whose **TTL (Time-to-Live)** has expired.  
- The **default TTL is 1 hour**, but this can be configured using the `--event-ttl` flag in the API server settings.  

### How Does Event Cleanup Work?
1. **Event is Created** → Stored in `etcd`.  
2. **TTL Countdown Begins** → Typically 1 hour unless configured otherwise.  
3. **Event Expires** → Becomes eligible for deletion.  
4. **Garbage Collection (Controller Manager)** → Detects expired events and removes them from `etcd`.  

### Key Takeaway:
- The API server **stores and serves** event data from `etcd`, but it **does not handle cleanup**.  
- The **controller manager** is responsible for **event garbage collection** after TTL expiration.  

Let me know if you need more details! 🚀
