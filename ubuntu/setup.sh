#!/bin/bash

set -e  # exit whenever a command failed

email=vailgrass@gmail.com

echo "install basic programs"
sudo apt update && sudo apt upgrade
# vim-gtk3 provides extended features like clipboard for ubuntu
programs=( curl wget zsh git vim-gtk3 fzf silversearcher-ag ripgrep )
sudo apt install ${programs[*]}

echo "copy config files"
cp ./.vimrc ./.zshrc ~

# public keys
filenames=( id_rsa.pub id_ecdsa.pub id_ed25519.pub )
for filename in $(ls -a ~/.ssh); do
  if [[ ${filenames[*]} =~ $filename ]]; then
    pub_key=$filename
  fi
done
if [[ ! -v pub_key ]]; then
  ssh-keygen -t rsa -b 4096 -C $email
  ssh-add ~/.ssh/id_rsa
  pub_key=~/.ssh/id_rsa.pub
fi
echo "public key is stored in $pub_key"

# git
echo "set git user email: $email"
git config --global user.email $email
echo "set git user name: Hangyu Feng"
git config --global user.name "Hangyu Feng"

# vim setup
if [ -d ~/.vim/bundle/Vundle.vim ]; then
  echo "update Vundle repo"
  cd ~/.vim/bundle/Vundle.vim && git pull && cd -
else
  echo "clone Vundle repo"
  git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim
fi
echo "install vim plugins"
vim +PluginInstall +qall

# zsh setup
if [ ! -d ~/.oh-my-zsh ]; then
  echo "~/.oh-my-zsh folder doesn't exist, install oh-my-zsh"
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
if [ ! -f ~/antigen.zsh ]; then
  echo "~/antigen.zsh folder doesn't exist, install antigen"
  curl -L git.io/antigen > ~/antigen.zsh  # zsh package manager
fi
if [[ ! $SHELL =~ zsh ]]; then
  chsh -s $(which zsh) && zsh
fi

