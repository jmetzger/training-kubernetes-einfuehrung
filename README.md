# Kubernetes Administration und Orchestrierung 

## Agenda

  1. Kubernetes - Überblick
     * [Allgemeine Einführung in Container (Dev/Ops)](overview-docker.md)
     * [Warum Kubernetes, was macht Kubernetes](warum-kubernetes.md)
     * [Microservices (Warum ? Wie ?) (Devs/Ops)](microservices.md) 
     * [Wann macht Kubernetes Sinn, wann nicht?](/kubernetes/wann-sinnvoll-wann-nicht.md)
     * [Aufbau Allgemein](/kubernetes/architecture.md)
     * [Aufbau mit helm,OpenShift,Rancher(RKE),microk8s](/kubernetes/aufbau-helm-microk8s-kubernetes.md)
     * [Welches System ? (minikube, micro8ks etc.)](welches-system.md)
     * [Installation - Welche Komponenten from scratch](/kubernetes/installation-components-overview.md)
  
  1. Kubernetes - microk8s (Installation und Management) 
     * [Installation Ubuntu - snap](microk8s/installation-ubuntu-snap.md)
     * [Remote-Verbindung zu Kubernetes (microk8s) einrichten](microk8s/connect-from-remote.md)
     * [Create a cluster with microk8s](microk8s/cluster.md)
     * [Ingress controller in microk8s aktivieren](microk8s/ingress.md) 
     * [Arbeiten mit der Registry](microk8s/registry.md)
     * [Installation Kuberenetes Dashboard](/microk8s/dashboard.md) 

  1. Kubernetes Praxis API-Objekte 
     * [Das Tool kubectl (Devs/Ops) - Spickzettel](/kubectl/spickzettel.md)
     * [kubectl example with run](/kubectl/run-with-example.md)
     * Arbeiten mit manifests (Devs/Ops)
     * Pods (Devs/Ops)
     * [kubectl/manifest/pod](/kubectl-examples/01-pod-nginx.md)
     * ReplicaSets (Theorie) - (Devs/Ops)
     * [kubectl/manifest/replicaset](/kubectl-examples/01a-replicaset-nginx.md)
     * Deployments (Devs/Ops)
     * [kubectl/manifest/deployments](/kubectl-examples/03-nginx-deployment.md)
     * Services (Devs/Ops)
     * [kubectl/manifest/service](/kubectl-examples/03b-service.md)
     * DaemonSets (Devs/Ops)
     * IngressController (Devs/Ops)
     * [Hintergrund Ingress](/kubernetes/ingress.md) 
     * [Documentation for default ingress nginx](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)
     * [Beispiel Ingress](/kubectl-examples/04-ingress-nginx.md)
     * [Beispiel mit Hostnamen](/kubectl-examples/04-ingress-nginx-with-hostnames.md)
     * [Achtung: Ingress mit Helm - annotations](/ingress-mit-helm-class-achtung.md)
     * [Permanente Weiterleitung mit Ingress](/kubectl-examples/05-ingress-permanent-redirect.md)
     * [ConfigMap Example](/kubectl-examples/06-configmap.md)

  1. Kubernetes - ENV - Variablen für den Container setzen
     * [ENV - Variablen - Übung](/kubernetes/uebungen-env-variablen.md)

  1. Kubernetes Secrets und Encrypting von z.B. Credentials 
     * [Kubernetes secrets Typen](/kubernetes/secrets/secrets.md) 
     * [Sealed Secrets - bitnami](/kubernetes/secrets/sealed-secrets.md) 

  1. Kubernetes Praxis Scaling/Rolling Updates/Wartung 
     * Rolling Updates (Devs/Ops) 
     * Scaling von Deployments (Devs/Ops) 
     * [Wartung mit drain / uncordon (Ops)](/kubectl/uncordon-drain.md) 
     * [Ausblick AutoScaling (Ops)](/kubernetes/autoscaling.md) 

  1. Kubernetes Storage 
     * Grundlagen (Dev/Ops)
     * Objekte PersistantVolume / PersistantVolumeClaim (Dev/Ops) 
     * [Praxis. Beispiel (Dev/Ops)](/shared-volumes/nfs-multiple.md) 

  1. Kubernetes Networking 
     * [Überblick](/kubernetes-networks/overview.md) 
     * Pod to Pod
     * Webbasierte Dienste (Ingress) 
     * IP per Pod
     * Inter Pod Communication ClusterDNS 
     * [Beispiel NetworkPolicies](/kubernetes-network/callico/00-simple-example-multi.md)

  1. Kubernetes Paketmanagement (Helm) 
     * [Warum ? (Dev/Ops)](helm/warum.md)
     * Grundlagen / Aufbau / Verwendung (Dev/Ops)
     * [Praktisches Beispiel bitnami/mysql (Dev/Ops)](/helm/example.md) 

  1. Kubernetes Rechteverwaltung (RBAC) 
     * Warum ? (Ops)
     * [Wie aktivieren?](/microk8s/rbac.md)
     * Rollen und Rollenzuordnung (Ops)
     * Service Accounts (Ops)
     * [Praktische Umsetzung anhand eines Beispiels (Ops)](/kubernetes/rbac-create-user-multi.md)

  1. Kubernetes Monitoring 
     * [Debugging von Ingress](/kubernetes/debugging-ingress.yml)
     * [Ebenen des Loggings](ebenen-des-loggings.md) 
     * [Working with kubectl logs](/kubectl/logs.md)
     * [Built-In Monitoring tools - kubectl top pods/nodes](microk8s/metrics-server.md)
     * [Protokollieren mit Elasticsearch und Fluentd (Devs/Ops)](microk8s/fluent-kibana-elastic-mit-microk8s.md)
     * [Long Installation step-by-step - Digitalocean](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-elasticsearch-fluentd-and-kibana-efk-logging-stack-on-kubernetes)
     * Container Level Monitoring (Devs/Ops)
     * [Setting up metrics-server - microk8s](/microk8s/metrics-server.md) 
  
  1. Kubernetes Security 
     * [Grundlagen und Beispiel (Praktisch)](security/grundlagen-security.md)

  1. Kubernetes GUI 
     * [Rancher](/kubernetes-gui/ranchner.md) 
     * [Kubernetes Dashboard](kubernetes-gui/kubernetes-dashboard.md) 


  1. Kubernetes CI/CD (Optional) 
     * Canary Deployment (Devs/Ops) 
     * Blue Green Deployment (Devs/Ops) 

  1. Tipps & Tricks 
     * [bash-completion](/kubectl/bash-completion.md) 
     * [Alias in Linux kubectl get -o wide](/kubectl/alias-o-wide.md)
     * [vim einrückung für yaml-dateien](/vim/vim-yaml.md)
     * [kubectl spickzettel](/kubectl/spickzettel.md)
     * [Alte manifests migrieren](/kubectl/convert-plugin.md)
    
  1. Fragen 
     * [Q and A](/q-and-a.md)

  1. Documentation
     * [Kubernetes mit VisualStudio Code](https://code.visualstudio.com/docs/azure/kubernetes)
     * [Kube Api Ressources - Versionierungsschema](/kubernetes/api-versionierung-lifetime.md)

## Backlog I

  1. Kubernetes - microk8s (Installation und Management) 
     * [Patch to next major release - cluster](microk8s/patch-next-major.md)
     * [Installation Kuberenetes Dashboard](/microk8s/dashboard.md) 

  1. Kubernetes - API - Objekte
  
     * [Was sind Deployments](/kubernetes/deployments.md)
     * [Service - Objekt und IP](/kubernetes/service.md)

  1. Kubernetes - Netzwerk (CNI's) 
     * [Übersicht Netzwerke](/kubernetes-networks/overview.md) 
     * [Callico - nginx example](/kubernetes-network/callico/00-simple-example.md)
     * [Callico - client-backend-ui-example](/kubernetes-network/callico/01-example-with-services.md)
   
  1. kubectl 
     * [Tipps&Tricks zu Deploymnent - Rollout](/kubectl/rollout.md) 
     
  1. kubectl - manifest - examples 
     * [05 Ingress mit Permanent Redirect](/kubectl-examples/05-ingress-permanent-redirect.md)

  1. Kubernetes - Monitoring (microk8s und vanilla) 
     * [metrics-server aktivieren (microk8s und vanilla)](/microk8s/metrics-server.md)

  1. Kubernetes - Tipps & Tricks 
     * [Assigning Pods to Nodes](/tipps-tricks/pods-2-nodes.md)

  1. Linux und Docker Tipps & Tricks allgemein 
     * [vim einrückung für yaml-dateien](/vim/vim-yaml.md)
     * [YAML Linter Online](http://www.yamllint.com/)
     

## Agenda 

  1. Docker-Grundlagen 
     * [Übersicht Architektur](architektur.md)
     * [Was ist ein Container ?](container.md)
     * [Was sind container images](container-images.md) 
     * [Container vs. Virtuelle Maschine](container-vs-vm.md)
     * [Was ist ein Dockerfile](dockerfile.md) 
  
  1. Docker-Installation
     * [Installation Docker unter Ubuntu mit snap](install-ubuntu-snap.md)
  
  1. Docker-Befehle 
     * [Die wichtigsten Befehle](docker-befehle.md)
     * [Logs anschauen - docker logs - mit Beispiel nginx](docker-logs-nginx.md)
     * [docker run](docker-run.md)
     * [Docker container/image stoppen/löschen](container-image-delete.md)
     * [Docker containerliste anzeigen](container-liste.md)
     * [Docker container analysieren](docker-inspect.md)
     * [Docker container in den Vordergrund bringen - attach](/docker/docker-attach.md) 
     * [Aufräumen - container und images löschen](prune-container-images.md)
     * [Nginx mit portfreigabe laufen lassen](docker-example-nginx.md)    
  
  1. Dockerfile - Examples 
     * [Ubuntu mit hello world](ubuntu-hello-world.md)
     * [Ubuntu mit ping](ubuntu-ping.md) 
     * [Nginx mit content aus html-ordner](nginx-html-content.md)
     * [ssh server](ubuntu-ssh-server.md)
  
  1. Docker-Container Examples 
     * [2 Container mit Netzwerk anpingen](2-containers-with-network-ping.md)
     * [Container mit eigenem privatem Netz erstellen](container-with-own-bridge.md)  
  
  1. Docker-Daten persistent machen / Shared Volumes 
     * [Überblick](storage-overview.md) 
     * [Volumes](storage-volumes.md) 
  
  1. Docker-Netzwerk 
     * [Netzwerk](network.md)
  
  1. Docker Compose
     * [yaml-format](yaml-format.md)
     * [Ist docker-compose installiert?](docker-compose-installed.md) 
     * [Example with Wordpress / MySQL](example-wordpress-mysql.md)
     * [Example with Wordpress / Nginx / MariadB](example-wnm-docker-compose.md)
     * [Example with Ubuntu and Dockerfile](example-docker-compose-ubuntu-build.md)
     * [Logs in docker - compose](docker-compose-logs.md)
     * [docker-compose und replicas](docker-compose-replicas.md)
  
  1. Docker Swarm 
     * [Docker Swarm Beispiele](docker-swarm-examples.md)

  1. Docker - Dokumentation 
     * [Vulnerability Scanner with docker](https://docs.docker.com/engine/scan/#prerequisites)
     * [Vulnerability Scanner mit snyk](https://snyk.io/plans/)
     * [Parent/Base - Image bauen für Docker](https://docs.docker.com/develop/develop-images/baseimages/)
    
  1. Kubernetes - Überblick
     * [Warum Kubernetes, was macht Kubernetes](warum-kubernetes.md) 
     * [Aufbau Allgemein](/kubernetes/architecture.md)
     * [Aufbau mit helm,OpenShift,Rancher(RKE),microk8s](/kubernetes/aufbau-helm-microk8s-kubernetes.md)
     * [Welches System ? (minikube, micro8ks etc.)](welches-system.md)
     * [Installation - Welche Komponenten from scratch](/kubernetes/installation-components-overview.md)

  1. Kubernetes - microk8s (Installation und Management) 
     * [Installation Ubuntu - snap](microk8s/installation-ubuntu-snap.md)
     * [Patch to next major release - cluster](microk8s/patch-next-major.md)
     * [Remote-Verbindung zu Kubernetes (microk8s) einrichten](microk8s/connect-from-remote.md)
     * [Create a cluster with microk8s](microk8s/cluster.md)
     * [Ingress controller in microk8s aktivieren](microk8s/ingress.md) 
     * [Arbeiten mit der Registry](microk8s/registry.md)
     * [Installation Kuberenetes Dashboard](/microk8s/dashboard.md) 

  1. Kubernetes - API - Objekte
     * [Welche API-Objekte gibt es? (Kommando)](/kubernetes/api-resources.md)
     * [Api Versionierung Lifetime](/kubernetes/api-versionierung-lifetime.md)
     * [Was sind Deployments](/kubernetes/deployments.md)
     * [Service - Objekt und IP](/kubernetes/service.md)
     * [Ingress -> Nginx Proxy](/kubernetes/ingress.md)

  1. Kubernetes - RBAC 
     * [Nutzer einrichten](/kubernetes/rbac-create-user.md) 
 
  1. Kubernetes - Netzwerk (CNI's) 
     * [Übersicht Netzwerke](/kubernetes-networks/overview.md) 
     * [Callico - nginx example](/kubernetes-network/callico/00-simple-example.md)
     * [Callico - client-backend-ui-example](/kubernetes-network/callico/01-example-with-services.md)
   
  1. kubectl 
     * [Start pod (container with run && examples)](/kubectl/run-with-example.md)
     * [Bash completion for kubectl](/kubectl/bash-completion.md)
     * [kubectl Spickzettel](/kubectl/spickzettel.md)
     * [Tipps&Tricks zu Deploymnent - Rollout](/kubectl/rollout.md) 
     
  1. kubectl - manifest - examples 
     * [02 Pod nginx mit Port und IP innerhalb des Clusters](/kubectl-examples/02-pod-nginx-exposed.md)
     * [03b Example with service and nginx](/kubectl-examples/03b-service.md)
     * [04 Ingress mit einfachem Beispiel](/kubectl-examples/04-ingress-nginx.md)
     * [05 Ingress mit Permanent Redirect](/kubectl-examples/05-ingress-permanent-redirect.md)

  1. Kubernetes - Monitoring (microk8s und vanilla) 
     * [metrics-server aktivieren (microk8s und vanilla)](/microk8s/metrics-server.md)

  1. Kubernetes - Shared Volumes 
     * [Shared Volumes with nfs](shared-volumes/nfs.md)

  1. Kubernetes - Backups 
     + [Kubernetes Aware Cloud Backup - kasten.io](/backups/cluster-backup-kasten-io.md)

  1. Kubernetes - Wartung 
     * [kubectl drain/uncordon](/kubectl/uncordon-drain.md)
     * [Alte manifeste konvertieren mit convert plugin](/kubectl/convert-plugin.md)

  1. Kubernetes - Tipps & Tricks 
     * [Assigning Pods to Nodes](/tipps-tricks/pods-2-nodes.md) 

  1. Kubernetes - Documentation 
     * [Documentation zu microk8s plugins/addons](https://microk8s.io/docs/addons)
     * [LDAP-Anbindung](https://github.com/apprenda-kismatic/kubernetes-ldap)
     * [Shared Volumes - Welche gibt es ?](https://kubernetes.io/docs/concepts/storage/volumes/)

  1. Linux und Docker Tipps & Tricks allgemein 
     * [Auf ubuntu root-benutzer werden](sudo.md)
     * [IP - Adresse abfragen](ip-a.md)
     * [Hostname setzen](hostname.md)
     * [Proxy für Docker setzen](proxy-docker.md)
     * [vim einrückung für yaml-dateien](/vim/vim-yaml.md)
     * [YAML Linter Online](http://www.yamllint.com/)
     * [Läuft der ssh-server](ssh-running.md)
     * [Basis/Parent - Image erstellen](docker-base-image.md)
     * [Eigenes unsichere Registry-Verwenden. ohne https](insecure-registry.md)

