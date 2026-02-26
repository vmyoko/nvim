build:
	@docker build . -t nvim-test
run:build
	@docker run -it --rm nvim-test

install-ubuntu:
	@apt update
	@apt install build-essential -y
	@apt install unzip -y
	@apt install git -y

	@snap refresh
	@snap install curl --classic
	@snap install nvim --classic

	@snap install pyenv --edge
	@pyenv install 1.14.2
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@chmod +x ~/.bashrc
	@~/.bashrc
	@bash -c 'export NVM_DIR="$$HOME/.nvm" && \
	[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" && \
	nvm install --lts && \
	nvm use --lts'

	@apt install clang -y
	@apt install gdb -y
	@apt install golang-go -y
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
	@nvim

install-debian:
	@apt update
	@apt install build-essential -y
	@apt install unzip -y
	@apt install git -y
	@apt install curl -y
	@curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	@rm -rf /opt/nvim-linux-x86_64
	@tar -C /opt -xzf nvim-linux-x86_64.tar.gz
	@NVIM_PATH := "$(PATH):/opt/nvim-linux-x86_64/bin" 
	@export PATH := $(NVIM_PATH)
	@apt install pyenv -y
	@pyenv install 3.12.2
	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@chmod +x ~/.bashrc
	@~/.bashrc
	@bash -c 'export NVM_DIR="$$HOME/.nvm" && \
	[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" && \
	nvm install --lts && \
	nvm use --lts'
	@apt install clang -y
	@apt install gdb -y
	@apt install golang-go -y
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
	@nvim
