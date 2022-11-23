# Kubernetes Alternatives

```
docker-compose 
==============

Vorteile:
>>>>>>>>>
Einfach zu lernen

Nachteile:
>>>>>>>>>>
Nur auf einem Host 
rudimentäre Features (kein loadbalancing)

Mittel der Wahl als Einstieg 


docker swarm 
============

Zitat Linux Magazin: Swarm ist das Gegenangebot zu Kubernetes für alle Admins, die gut mit den Docker-Konventionen leben können und den Umgang mit den Standard-Docker-APIs gewöhnt sind. Sie haben bei Swarm weniger zu lernen als bei Kubernetes.



Vorteile:
>>>>>>>>>
Bereits in Docker integriert (gleiche Komandos)
Einfacher zu lernen 


Nachteile:
>>>>>>>>>>
Kleinere Community
Kleineres Feature-Set als Kubernetes
(Opinion): Bei vielen Containern wird es unhandlich



openshift 4 (Redhat)
===========

- Verwendet als runtime: CRI-O (Redhat) 


Vorteile:
>>>>>>>>>

Container laufen nicht als root (by default) 
Viele Prozesse bereits mitgedacht als Tools 
?? Applikation deployen ??

In OpenShift 4 - Kubernetes als Unterbau 


Nachteile: 
>>>>>>>>>>
o Lizenzgebühren (Redhat) 
o kleinere Userbase 




mesos
=====

Mesos ist ein Apache-Projekt, in das Mesospheres Marathon und DC/OS eingeflossen sind. Letzteres ist ein Container-Betriebssystem. Mesos ist kein Orchestrator im eigentlichen Sinne. Vielmehr könnte man die Lösung als verteiltes Betriebssystem bezeichnen, das eine gemeinsame Abstraktionsschicht der Ressourcen, auf denen es läuft, bereitstellt.


Vorteile:

Nachteile:


Rancher
=======
Graphical frontend, build on containers to deploy multiple kubernetes clusters

```
