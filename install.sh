apt update

apt install curl git unzip -y

curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz

rm -rf /opt/nvim-linux-x86_64

tar -C /opt -xzf nvim-linux-x86_64.tar.gz

curl -fsSL https://pyenv.run | bash

pyenv install 3.14.2

curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

nvm install --lts 


