build:
	@docker build . -t nvim-test
run:build
	@docker run -it --rm nvim-test

install-ubuntu-snap:
	@apt update
	@apt install build-essential
	@apt install unzip
	@apt install git

	@snap refresh
	@snap install curl --classic
	@snap install nvim --classic

	@snap install pyenv --classic
	@pyenv install 1.14.2
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@nvm install --lts
	@nvm use --lts

	@apt install clang
	@apt install gdb
	@apt install golang-go
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

install-debian:
	@apt update
	@apt install build-essential
	@apt install unzip
	@apt install git
	@apt install curl
	@curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	@rm -rf /opt/nvim-linux-x86_64
	@tar -C /opt -xzf nvim-linux-x86_64.tar.gz
	@export PATH="$:/opt/nvim-linux-x86_64/bin"
	@apt install pyenv
	@pyenv install 3.12.2
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@source ~/.bashrc
	@source ~/.bash_profile
	@source ~/.profile
	@nvm install --lts
	@nvm use --lts
	@apt install clang
	@apt install gdb
	@apt install golang-go
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
