## Client-Installation unter Ubuntu 22.04 LTS 

```
# Now let us do some generic setup 
echo "Installing kubectl"
snap install --classic kubectl

echo "Installing helm"
snap install --classic helm 

apt-get update 
apt-get install -y bash-completion
source /usr/share/bash-completion/bash_completion
# is it installed properly
type _init_completion

# activate for all users
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null

# Activate syntax - stuff for vim
# Tested on Ubuntu 
echo "hi CursorColumn cterm=NONE ctermbg=lightred ctermfg=white" >> /etc/vim/vimrc.local 
echo "autocmd FileType y?ml setlocal ts=2 sts=2 sw=2 ai number expandtab cursorline cursorcolumn" >> /etc/vim/vimrc.local 

# Activate Syntax highlightning for nano 
cd /usr/local/bin
git clone https://github.com/serialhex/nano-highlight.git 
# Now set it generically in /etc/nanorc to work for all 
echo 'include "/usr/local/bin/nano-highlight/yaml.nanorc"' >> /etc/nanorc 
```
