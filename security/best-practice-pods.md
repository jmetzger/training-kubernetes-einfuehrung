# Security Pods 

```
5. Security / Best practice pods 

5.1. Pods 
1) Use Readiness / Liveness check 

Not we really security, but to have a stable system 

2) Use Non-Root Images 
(is not allowed in OpenShift anyways)

3) SecurityContext: Restrict the Features in the pod/container as much as possible

Essentially covered by Default SCC's:
https://docs.openshift.com/container-platform/4.18/authentication/managing-security-context-constraints.html

Essentially use the v2 versions. 

Question will Always be: Do I really Need this for this post 
(e.g. HostNetwork). Is there are better/safer way to achieve this 
```
