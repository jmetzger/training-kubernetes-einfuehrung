# Self-Service Stack ausrollen (pro Teilnehmer) 

  * ausgerollt mit terraform (binary ist installiert) - snap install --classic terraform 
  * beinhaltet
      1. 1      controlplane
      1. 2 worker nodes
      1. metallb mit ips der Nodes (hacky but works)
      1. ingress mit wildcard-domain:  *.tlnx.do.t3isp.de
      1. cert-manager mit helmfile sync 

## Prerequisites 

```
# in /tmp/.env ist die Umgebungsvariable wie folgt gesetzt
export TF_VAR_do_token=<dein-do-token>
```
   
## Walktrough 

```
cd
git clone https://github.com/jmetzger/training-istio-kubernetes-stack-do-terraform.git install
cd install
cat /tmp/.env
source /tmp/.env
terraform init
terraform apply -auto-approve
#
helmfile sync 
```

## Hinweis

```
# Sollte es nicht sauber durchlaufen
# einfach nochmal
terraform apply -auto-approve

# Wenn das nicht geht, einfach nochmal neu
terraform destroy -auto-approve
terraform apply -auto-approve
```
