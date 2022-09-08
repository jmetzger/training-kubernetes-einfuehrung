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
     * [Ingress Controller auf Digitalocean (doks) mit helm installieren](/digitalocean/ingress-auf-digitalocean-mit-helm.md)
     * [Documentation for default ingress nginx](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/)
     * [Beispiel Ingress](/kubectl-examples/04-ingress-nginx.md)
     * [Beispiel mit Hostnamen](/kubectl-examples/04-ingress-nginx-with-hostnames.md)
     * [Achtung: Ingress mit Helm - annotations](/ingress-mit-helm-class-achtung.md)
     * [Permanente Weiterleitung mit Ingress](/kubectl-examples/05-ingress-permanent-redirect.md)
     * [ConfigMap Example](/kubectl-examples/06-configmap.md)

 1. Kubernetes Storage 
     * [Praxis. Beispiel (Dev/Ops)](/shared-volumes/nfs-multiple.md) 

 1. Kubernetes Secrets / ConfigMap 
 
 
 1. Kubernetes Operator Konzept 
    
    * [Kubernetes Operator Konzept](/kubernetes/operator/overview.md)

 1. Tipps & Tricks 
    * [Ubuntu client aufsetzen](/tipps-tricks/ubuntu-client.md)
    * [Netzwerkverbindung zum Pod testen](/tipps-tricks/verbindung-zu-pod-testen.md)
   

## Backlog 

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

  1. Kubernetes Monitoring 
     * [Debugging von Ingress](/kubernetes/debugging-ingress.md)
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

