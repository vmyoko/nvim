build:
	@docker build . -t nvim-test
run:build
	@docker run -it --rm nvim-test

install-ubuntu-snap:
	@sudo apt update
	@sudo apt install build-essential
	@sudo apt install unzip
	@sudo apt install git

	@sudo snap refresh
	@sudo snap install curl --classic
	@sudo snap install nvim --classic

	@sudo snap install pyenv --classic
	@sudo pyenv install 1.14.2
	@sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@sudo nvm install --lts
	@sudo nvm use --lts

	@sudo apt install clang
	@sudo apt install gdb
	@sudo apt install golang-go
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh

install-debian:
	@sudo apt update
	@sudo apt install build-essential
	@sudo apt install unzip
	@sudo apt install git
	@sudo apt install curl
	@curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	@sudo rm -rf /opt/nvim-linux-x86_64
	@sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
	@export PATH="$:/opt/nvim-linux-x86_64/bin"
	@sudo apt install pyenv
	@sudo pyenv install 3.12.2
	@sudo curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@source ~/.bashrc
	@source ~/.bash_profile
	@source ~/.profile
	@sudo nvm install --lts
	@sudo nvm use --lts
	@sudo apt install clang
	@sudo apt install gdb
	@sudo apt install golang-go
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
