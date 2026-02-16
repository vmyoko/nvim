#!/bin/bash -e

while ! kill -0 $(pidof snapd); do
  echo "Waiting for snapd to start."
  sleep 1
done

echo "Snapd started!"

snap refresh

snap install curl --classic
snap install git --classic
snap install unzip --classic
snap install nvim --classic

rm -rf /opt/nvim-linux-x86_64

tar -C /opt -xzf nvim-linux-x86_64.tar.gz

export PATH=$PATH:/opt/nvim-linux-x86_64/bin

snap install pyenv --edge

pyenv install 3.14.2

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts 
nvm use --lts
