# Bash-completion (Ubuntu) 

## Walkthrough 

```
apt install bash-completion
source /usr/share/bash-completion/bash_completion
# is it installed properly 
type _init_completion

# activate for all users 
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# verifizieren - neue login shell
su -

# zum Testen
kubectl g<TAB> 
kubectl get 
```
## Alternative für k als alias für kubectl 

```
source <(kubectl completion bash)
complete -F __start_kubectl k

```

```
# für permanente Nutzungn
# eintragen in ~/.bash_profile oder anlegen, wenn datei nicht vorhanden
alias k=kubectl
complete -o default -F __start_kubectl k
```

```
# und danach rausgehen und entweder
# Session neu starten
# pder su - <benutzername>
```

## Reference 

  * https://kubernetes.io/docs/tasks/tools/included/optional-kubectl-configs-bash-linux/
