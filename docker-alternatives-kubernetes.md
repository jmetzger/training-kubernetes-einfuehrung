# Docker Alternativen in Kubernetes 

## Grundlagen 

  * Container und Images sind nicht docker-spezifisch, sondern folgen der OCI Spezifikation (Open Container Initiative) 
  * D.h. die "Bausteine" Image, Container, Registry sind standards
  * Ich brauche kein Docker, um Images zu bauen, es gibt Alternativen:
    * z.B. buildah 
  * kubelet -> redet mit CRI (Container Runtime Interface) -> Redet mit Container Runtime z.B. containerd (Docker), CRI-O (Redhat)
    * [CRI](https://kubernetes.io/docs/concepts/architecture/cri/)

## Hintergründe 

  * Container Runtime (CRI-O, containerd) 
  * [OCI image (Spezifikation)](https://github.com/opencontainers/image-spec)
  * OCI container (Spezifikation) 
  * [Sehr gute Lernreihe zu dem Thema Container (Artikel)](https://iximiuz.com/en/posts/not-every-container-has-an-operating-system-inside/)
