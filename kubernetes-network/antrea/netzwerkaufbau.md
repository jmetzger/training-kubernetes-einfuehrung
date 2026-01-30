# Netzwerkaufbau 

<img width="914" height="299" alt="image" src="https://github.com/user-attachments/assets/7d17926e-6cd4-461d-9f9d-81505943884a" />

## Besonderheit Netzwerk 

  * Dann kannst direkt von anderen VM's in ESXi in einen Pod reinrouten
  * Eine VM kann einen Pod im Kubernetes Cluster über sein Pod-IP direkt erreichen

## Konsequenz des Netzwerkaufbau 

  * Range für Pods (IP-Range) -> Cluster CIDR, darf nicht schon nsx verwendet worden sein


