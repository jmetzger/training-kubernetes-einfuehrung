# Resources 

## Where ?

  * Used in base

```
# base/kustomization.yml 
# which resources to use 
# e.g 
resources: 
  - my-manifest.yml 

```

## Which ?

  * URL
  * filename 
  * Repo (git) 

## Example:

```
# kustomization.yaml
resources:
# a repo with a root level kustomization.yaml
- github.com/Liujingfang1/mysql
# a repo with a root level kustomization.yaml on branch test
- github.com/Liujingfang1/mysql?ref=test
# a subdirectory in a repo on branch repoUrl2
- github.com/Liujingfang1/kustomize/examples/helloWorld?ref=repoUrl2
# a subdirectory in a repo on commit `7050a45134e9848fca214ad7e7007e96e5042c03`
- github.com/Liujingfang1/kustomize/examples/helloWorld?ref=7050a45134e9848fca214ad7e7007e96e5042c03
```
