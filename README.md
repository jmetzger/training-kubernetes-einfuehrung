# Kubernetes Einführung

## Agenda 

  1. Docker-Grundlagen 
     * [Übersicht Architektur](architektur.md)
     * [Was ist ein Container ?](container.md)
     * [Was sind container images](container-images.md) 
     * [Container vs. Virtuelle Maschine](container-vs-vm.md)
     * [Was ist ein Dockerfile](dockerfile.md) 
     * [Dockerfile - image kleinhalten](dockerfile-image-small.md)
    
  1. Kubernetes - Überblick
     * [Warum Kubernetes, was macht Kubernetes](warum-kubernetes.md)
     * [Aufbau Allgemein](/kubernetes/architecture.md)
     * [Kubernetes Architektur Deep-Dive](https://github.com/jmetzger/training-kubernetes-advanced/assets/1933318/1ca0d174-f354-43b2-81cc-67af8498b56c)
     * [Ausbaustufen Kubernetes](installer/kubernetes-ausbaustufen.md)
     * [Wann macht Kubernetes Sinn, wann nicht?](/kubernetes/wann-sinnvoll-wann-nicht.md)   
     * [Aufbau mit helm,OpenShift,Rancher(RKE),microk8s](/kubernetes/aufbau-helm-microk8s-kubernetes.md)
     * [Welches System ? (minikube, micro8ks etc.)](welches-system.md)
     * [Installer für grosse Cluster](/kubernetes/grosse-installation-installer.md)
     * [Installation - Welche Komponenten from scratch](/kubernetes/installation-components-overview.md)

  1. Kubernetes - Überblick
     * [Liste wichtiger/sinnvoller Client-Tools](https://github.com/jmetzger/training-kubernetes-einfuehrung/blob/main/tools/liste-client-tools.md)

  1. kubectl 
     * [kubectl einrichten mit namespace](/kubectl/kubectl-einrichten.md)
     * [kubectl cheatsheet kubernetes](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
     * [kubectl mit verschiedenen Clustern arbeiten](/kubectl/use-context.md)

  1. Kubernetes Ingress (Eingehender Traffik ins Cluster)
     * [Wann LoadBalancer, wann Ingress](ingress/ingress-vs-loadbalancer.md)

  1. Kubernetes Praxis API-Objekte 
     * [Das Tool kubectl (Devs/Ops) - Spickzettel](/kubectl/spickzettel.md)
     * [kubectl example with run](/kubectl/run-with-example.md)
     * [Bauen einer Applikation mit Resource Objekten](bauen-einer-webanwendung.md)
     * [Anatomie einer Webanwendungen](anatomie-einer-webanwendung.md)
     * [kubectl/manifest/pod](/kubectl-examples/01-pod-nginx.md)
     * ReplicaSets (Theorie) - (Devs/Ops)
     * [kubectl/manifest/replicaset](/kubectl-examples/01a-replicaset-nginx.md)
     * Deployments (Devs/Ops)
     * [kubectl/manifest/deployments](/kubectl-examples/03-nginx-deployment.md)
     * Debugging 
     * [Netzwerkverbindung zum Pod testen](/tipps-tricks/verbindung-zu-pod-testen.md)  
     * Services (Devs/Ops)
     * [kubectl/manifest/service](/kubectl-examples/03b-service.md)
     * DaemonSets (Devs/Ops)
     * IngressController (Devs/Ops)
     * [Hintergrund Ingress](/kubernetes/ingress.md) 
     * [Ingress Controller auf Digitalocean (doks) mit helm installieren](/digitalocean/ingress-auf-digitalocean-mit-helm.md)
     * [Documentation for default ingress nginx](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)
     * [Beispiel Ingress](/kubectl-examples/04-ingress-nginx.md)
     * [Beispiel mit Hostnamen](/kubectl-examples/04-ingress-nginx-with-hostnames.md)
     * [Beispiel Deployment mit Ingress und Hostnamen](kubectl-examples/04-ingress-nginx-with-hostnames-deployment.md)
     * [Achtung: Ingress mit Helm - annotations](/ingress-mit-helm-class-achtung.md)
     * [Permanente Weiterleitung mit Ingress](/kubectl-examples/05-ingress-permanent-redirect.md)
     * [ConfigMap Example](/kubectl-examples/06-configmap.md)
     * [ConfigMap Example MariaDB](/kubectl-examples/06a-configmap-mariadb.md)
     * [Secrets Example MariaDB](/kubectl-examples/07-mariadb-secret.md)
     * [Connect to external database](/databases/connect-to-external-db.md)

  1. Kubernetes Praxis (Stateful Sets)
     * [Hintergrund statefulsets](/kubernetes/statefulsets.md)
     * [Example stateful set](/kubectl-examples/10-statefulset.md)

  1. Kubernetes Secrets und Encrypting von z.B. Credentials 
     * [Kubernetes secrets Typen](/kubernetes/secrets/secrets.md) 
     * [Sealed Secrets - bitnami](/kubernetes/secrets/sealed-secrets.md)
     * [Exercise Sealed Secret mariadb](/kubectl-examples/08-sealed-secret.md)
     * [registry mit secret auth](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/)

  1. Kubernetes API-Objekte (Teil 2)
     *  [Jobs](kubectl-examples/12-job.md)
     *  [Cronjobs](kubectl-examples/11-cronjob.md)
     *  [DaemonSet - einfaches Beispiel](kubectl-examples/14-daemonset-simple.md)
     *  [Daemonset with HostPort](kubectl-examples/13-daemonset-hostport.md)
     *  [Daemonset with HostNetwork](/kubectl-examples/14-daemonset-hostnetwork.md)

  1. Kubernetes Praxis
     * [Befehle in pod ausführen - Übung](kubectl-examples/15-exec-example.md)
     * [Welche Pods mit Namen gehören zu einem Service](tipps-tricks/welche-pods-mit-namen-gehoeren-zu-einem-service.md)

  1. Security
     * [ServiceLinks nicht in env in Pod einbinden](security/service-nicht-einhaengen-in-pod.md)

  1. Helm (Kubernetes Paketmanager)
     * [Helm - Was kann Helm](helm/was-kann-helm.md)
     * [Helm Spickzettel](/helm/spickzettel.md)
     * [Helm - Was kann Helm](helm/was-kann-helm.md)
     * [Helm Grundlagen](/helm/grundlagen.md)
     * [Helm Warum ?](/helm/warum.md)
     * [Helm Example](/helm/example.md)
     * [Helm Exercise with nginx](/helm/exercise-nginx.md)

  1. Helm - Fehleranalye
     * [Beispiel Cloudpirates - helm chart nginx](helm/cloudpirates-helm-chart-nginx-fehleranalyse.md)

  1. Helpful plugins
     * [Use shortnames for kubectl - commands](https://gist.github.com/doevelopper/ff4a9a211e74f8a2d44eb4afb21f0a38)

  1. Kubernetes Debugging
     * [Probleme über Logs identifiziert - z.B. non-root image](kubectl-examples/16-run-pod-as-unprivileged-user.md)
   
  1. Weiter lernen 
     * [Lernumgebung](https://killercoda.com/)
     * [Kubernetes Doku - Bestimmte Tasks lernen](https://kubernetes.io/docs/tasks/configure-pod-container/assign-memory-resource/)
     * [Kubernetes Videos mit Hands On](https://www.youtube.com/watch?v=16fgzklcF7Y)

  1. Kubernetes Storage (CSI) 
     * [Überblick Persistant Volumes (CSI)](kubernetes-csi/overview.md)
     * [Liste der Treiber mit Features (CSI)](https://kubernetes-csi.github.io/docs/drivers.html)
     * [Übung Persistant Storage](kubernetes-csi/nfs-exercise.md)
     * [Beispiel mariadb](kubernetes-csi/example-mariadb.md)
   
  1. Kubernetes Installation
     * [k3s installation](/installation/k3s.md)
    
  1. Kubernetes Monitoring 
     * [Prometheus Monitoring Server (Overview)](prometheus/overview.md)
     * [Prometheus / Grafana Stack installieren](prometheus-grafana/install-with-helm.md)
 
  1. Kubernetes QoS / HealthChecks / Live / Readiness
     * [Quality of Service - evict pods](kubernetes/qos-class.md)
     * [LiveNess/Readiness - Probe / HealthChecks](probes/uebung-liveness.md)
     * [Taints / Toleratioins](kubernetes/taints-tolerations.md)
    
  1. Installation mit microk8s
     * [Schritt 1: auf 3 Maschinen mit Ubuntu 24.04LTS](microk8s/installation-ubuntu-snap.md)
     * [Schritt 2: cluster - node2 + node3 einbinden - master ist node 1](microk8s/cluster.md)
     * [Schritt 3: Remote Verbindung einrichten](microk8s/cluster.md)
    
  1. Installation mit kubeadm
     * [Schritt für Schritt mit kubeadm](kubeadm/installation-cni-calico.md)
     

## Backlog 

  1. Podman
     * [Podman vs. Docker](podman/podman-vs-docker.md) 

  1. ServiceMesh
     * [Why a ServiceMesh ?](istio/overview/benefits-of-a-service-mesh.md)
     * [How does a ServiceMeshs work? (example istio](/istio/overview/overview-classic-sidecar.md)
     * [istio vs. ingress](istio/00-istio-vs-ingress.md)
     * [istio security features](istio/overview/security-features.md)
     * [istio-service mesh - ambient mode](/istio/overview/ambient-mode.md)
     * [Performance comparison - baseline,sidecar,ambient](/istio/overview/performance-comparison-baseline-sidecar-ambient.md)

  1. Kubernetes Ingress
     * [Ingress HA-Proxy Sticky Session](ingress/ha-proxy/load-balancing-sticky-session.md)
     * [Nginx Ingress Session Stickyness](ingress/nginx/session-stickyness.md)
     * [https mit ingressController und Letsencrypt](ingress/https-letsencrypt.md)  
         
  1. Kubernetes Pod Termination
     * [LifeCycle Termination](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination)
     * [preStopHook](https://www.datree.io/resources/kubernetes-guide-graceful-shutdown-with-lifecycle-prestop-hook)
     * [How to wait till a pod gets terminated](pods/termination/hooks.md)
           
  1. Kubernetes Security
     * [Best practices security pods](security/best-practice-pods.md)
     * [Best practices in general](security/security-best-practices.md)
     * [Images in kubernetes von privatem Repo verwenden](kubectl-examples/19-imagepullsecrets.md)

  1. Kubernetes Monitoring/Security
     * [Überwachung, ob Images veraltet sind, direkt in Kubernetes](kubernetes-monitoring/keel-monitor-outdated-images.md)

  1. Helm (IDE - Support) 
     * [Kubernetes-Plugin Intellij](https://www.jetbrains.com/help/idea/kubernetes.html)
     * [Intellij - Helm Support Through Kubernetes Plugin](https://blog.jetbrains.com/idea/2018/10/intellij-idea-2018-3-helm-support/)

  1. Helm - Charts enwickeln
     * [Unser erstes Helm Chart erstellen](helm/exercises/04a-create-chart-my-app-gruppenarbeit.md)
     * [Wie starte ich am besten - Übung](helm/exercises/05-einfach-starten.md)

  1. Helm und Kustomize kombinieren
     * [Helm und Kustomize kombinieren](helm-kustomize/combine-helm-and-kustomize.md)
       
  1. LoadBalancer on Premise (metallb)
     * [Metallb](/metallb.md)
       
  1. Helm mit gitlab ci/cd
     * [Helm mit gitlab ci/cd ausrollen](helm/helm/gitlab-ci-cd/example-helm-kubernetes.md)
    
  1. Kubernetes Verläßlichkeit erreichen 
     * [Keine 2 pods auf gleichem Node - PodAntinAffinity](kubectl-examples/18-pod-anti-affinity.md)
      
  1. Metrics-Server / Größe Cluster 
     * [Metrics-Server mit helm installieren](metrics-server-helm.md)
     * [Speichernutzung und CPU berechnen für Anwendungen](https://learnk8s.io/kubernetes-node-size)

  1. Kubernetes -> High Availability Cluster (multi-data center)
     * [High Availability multiple data-centers](ha/overview.md)
     * [PodAntiAffinity für Hochverfügbarkeit](kubernetes-ha/podtiAffinity.md)
     * [PodAffinity](ha/pod-affinity.md)

  1. Kubernetes -> etcd
     * [etcd - cleaning of events](etcd/garbage-collection-events.md)
     * [etcd in multi-data-center setup](/etcd/overview.md)
  
  1. Kubernetes Storage 
     * [Praxis. Beispiel (Dev/Ops)](/shared-volumes/nfs-multiple.md)

  1. Kubernetes Netzwerk 
     * [Kubernetes Netzwerke Übersicht](kubernetes-networks/overview.md)
     * [DNS - Resolution - Services](kubernetes-networks/dns-resolution-services.md)
     * [Kubernetes Firewall / Cilium Calico](/kubernetes-network/callico/00-simple-example-multi.md)
     * [Sammlung istio/mesh](sammlung-istio.md)

  1. Kubernetes NetworkPolicy (Firewall)
     * [Kubernetes Network Policy Beispiel](kubernetes-networkpolicy/00-simple-exercises-group.md)    

  1. Kubernetes Autoscaling 
     * [Kubernetes Autoscaling](/kubernetes/autoscaling.md)

  1. Kubernetes Secrets / ConfigMap 
     * [Configmap Example 1](/kubectl-examples/06-configmap.md)
     * [Secrets Example 1](kubernetes/secrets/uebung-secrets.md)
     * [Änderung in ConfigMap erkennen und anwenden](https://github.com/stakater/Reloader)
    
  1. Kubernetes RBAC (Role based access control)
     * [RBAC Übung kubectl](/kubernetes/rbac-create-user-kubernetes-1-25.md)

  1. Kubernetes Operator Konzept 
     * [Ueberblick](kubernetes/operator/overview.md)   
    
  1. Kubernetes Deployment Strategies
     * [Deployment green/blue,canary,rolling update](/deployment-strategies-en.md)
     * [Praxis-Übung A/B Deployment](/kubectl-examples/08-ab-deployment.md)
     
  1. Kubernetes Monitoring 
     * [Prometheus / blackbox exporter](prometheus-grafana/z_blackbox-exporter.md)
     * [Kubernetes Metrics Server verwenden](kubernetes-monitoring/metrics-server-installieren-und-verwenden.md)

  1. Tipps & Tricks 
     * [Netzwerkverbindung zum Pod testen](/tipps-tricks/verbindung-zu-pod-testen.md)
     * [Debug Container neben Container erstellen](kubernetes-networks/debug-container.md)
     * [Debug Pod auf Node erstellen](tipps-tricks/kubectl-debug-node.md)
     
  1. Kubernetes Administration /Upgrades 
     * [Kubernetes Administration / Upgrades](kubernetes-cluster-update-path.md)
     * [Terminierung von Container vermeiden](avoid-termination-container.md)
     * [Praktische Umsetzung RBAC anhand eines Beispiels (Ops)](/kubernetes/rbac-create-user-multi.md)

  1. Documentation (Use Cases) 
     * [Case Studies Kubernetes](https://kubernetes.io/case-studies/)
     * [Use Cases](https://codilime.com/blog/harnessing-the-power-of-kubernetes-7-use-cases/)
     
  1. Interna von Kubernetes 
     * [OCI,Container,Images Standards](docker-alternatives-kubernetes.md)
   
  1. Andere Systeme / Verschiedenes  
     * [Kubernetes vs. Cloudfoundry](kubernetes-vs-cloudfoundry.md)
     * [Kubernetes Alternativen](kubernetes-alternatives.md)
     * [Hyperscaler vs. Kubernetes on Premise](hyperscaler-vs-kubernetes.md)
     
  1. Lokal Kubernetes verwenden 
     * [Kubernetes in ubuntu installieren z.B. innerhalb virtualbox](/microk8s/installation-ubuntu-snap.md)
     * [minikube](/minikube/installation.md)
     * [rancher for desktop](https://github.com/rancher-sandbox/rancher-desktop/releases/tag/v1.9.1)
     
  1. Microservices 
     * [Microservices vs. Monolith](/microservices/monolith-vs-microservice.md)
     * [Monolith schneiden/aufteilen](/microservices/monolith-schneiden.md)
     * [Strategic Patterns - wid monolith praktisch umbauen](microservices/strategic-patterns.md)
     * [Literatur von Monolith zu Microservices](https://www.amazon.de/Vom-Monolithen-Microservices-bestehende-umzugestalten/dp/3960091400/)

  1. Extras 
     * [Install minikube on wsl2](installer/minikube-wsl2.md)
     * [kustomize - gute Struktur für größere Projekte](/kustomize/kustomize-big-projects.md)
     * [kustomize with helm](https://fabianlee.org/2022/04/18/kubernetes-kustomize-with-helm-charts/)
    
  1. Documentation
     * [References](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/#DeploymentSpec)
     * [Tasks Documentation - Good one !](https://kubernetes.io/docs/tasks)
    
  1. AWS
     * [ECS (managed containers) vs. Kubernetes](aws/ecs-vs-kubernetes.md)
 
  1. Documentation for Settings right resources/limits
     * [Goldilocks](https://www.fairwinds.com/blog/introducing-goldilocks-a-tool-for-recommending-resource-requests)

## Backlog 

  1. Kubernetes - Überblick
     * [Allgemeine Einführung in Container (Dev/Ops)](overview-docker.md)
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

  1. Kubernetes - Arbeiten mit einer lokalen Registry (microk8s) 
     * [microk8s lokale Registry](/microk8s/registry.md)

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
     * [Warum ? (Dev/Ops)](/helm/warum.md)
     * [Grundlagen / Aufbau / Verwendung (Dev/Ops)](/helm/grundlagen.md)
     * [Praktisches Beispiel bitnami/mysql (Dev/Ops)](/helm/example.md) 

  1. Kustomize
     * [Beispiel ConfigMap - Generator](/kustomize/01-example-configmap.md)
     * [Beispiel Overlay und Patching](/kustomize/02-overlay-example.md)
     * [Resources](/kustomize/resources.md)

  1. Kubernetes Rechteverwaltung (RBAC) 
     * Warum ? (Ops)
     * [Wie aktivieren?](/microk8s/rbac.md)
     * Rollen und Rollenzuordnung (Ops)
     * Service Accounts (Ops)
     * [Praktische Umsetzung anhand eines Beispiels (Ops)](/kubernetes/rbac-create-user-multi.md)

  1. Kubernetes Backups 
     * [Kubernetes Backup](/backups/cluster-backup-kasten-io.md)
     * [Kasten.io overview](https://docs.kasten.io/latest/usage/overview.html)

  1. Kubernetes Monitoring 
     * [Debugging von Ingress](/kubernetes/debugging-ingress.md)
     * [Ebenen des Loggings](ebenen-des-loggings.md) 
     * [Working with kubectl logs](/kubectl/logs.md)
     * [Built-In Monitoring tools - kubectl top pods/nodes](/metrics-server-helm.md)
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
     * [Ubuntu client aufsetzen](/tipps-tricks/ubuntu-client.md)
     * [bash-completion](/kubectl/bash-completion.md) 
     * [Alias in Linux kubectl get -o wide](/kubectl/alias-o-wide.md)
     * [vim einrückung für yaml-dateien](/vim/vim-yaml.md)
     * [kubectl spickzettel](/kubectl/spickzettel.md)
     * [Alte manifests migrieren](/kubectl/convert-plugin.md)
     * [X-Forward-Header-For setzen in Ingress](/ingress-forward-for-header.md)
  
  1. Übungen 
     * [übung Tag 3](/uebungen/tag3.md) 
     * [übung Tag 4](/uebungen/tag4.md) 
  
  1. Fragen 
     * [Q and A](/q-and-a.md)
     * [Kuberenetes und Ansible](/kubernetes-and-ansible.md)

  1. Documentation
     * [Kubernetes mit VisualStudio Code](https://code.visualstudio.com/docs/azure/kubernetes)
     * [Kube Api Ressources - Versionierungsschema](/kubernetes/api-versionierung-lifetime.md)
     * [Kubernetes Labels and Selector](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
    
  1. Documentation - Sources
     * [controller manager](https://github.com/kubernetes/kubernetes/tree/release-1.29/cmd/kube-controller-manager/app/options)

     
  

