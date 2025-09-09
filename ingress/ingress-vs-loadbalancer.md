# Loadbalancer (service type: LoadBalancer) 

## Vorteile Load-Balancer 

  * Ich brauche keine https Termination
  * Es ist mir egal wieviel IP-Adresse ich verbrate (weil 1 (eine !) IP pro Service
  * kein http-Dienst sondern tcp stream or grpc)

## Nachteile sind 

  * Keine Routing von Pfaden (d.h. http://meine-domain.de und http://meine-domain.de/backend gehen beide zum gleich Service)
  * Kein Auswertung von HTTP-Headern
  * Sehr schlechte Stickyness - Features (maximal bindung über die IP) 


## Vorteile von Ingress (gut für http und https)

  * Routing von Pfaden ( (d.h. http://meine-domain.de und http://meine-domain.de/backend gehen beide zu unterschiedlichen Services)
  * Auswertung von HTTP-Headern
  * Anbieter mit sehr guter Session Stickyness
  * Nur eine IP für alle Dienste (die IP, die Ingress selbst benötigt, um erreichbar zu sein)
  * HTTPS Termination
