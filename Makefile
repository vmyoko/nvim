NVIM_PATH := "/opt/nvim-linux-x86_64/bin"

build:
	@docker build . -t nvim-test

run: build
	@docker run -it --rm nvim-test

install-ubuntu:
	@apt update
	@apt install -y build-essential unzip git curl cmake clang gdb golang-go \
		libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
		libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

	@snap refresh
	@snap install nvim --classic

	@rm -rf ~/.pyenv
	@curl https://pyenv.run | bash
	@echo 'export PYENV_ROOT="$$HOME/.pyenv"' >> ~/.bashrc
	@echo '[[ -d $$PYENV_ROOT/bin ]] && export PATH="$$PYENV_ROOT/bin:$$PATH"' >> ~/.bashrc
	@echo 'eval "$$(pyenv init -)"' >> ~/.bashrc
	@bash -c 'export PYENV_ROOT="$$HOME/.pyenv" && \
		export PATH="$$PYENV_ROOT/bin:$$PATH" && \
		eval "$$(pyenv init -)" && \
		pyenv install 3.13.3 && \
		pyenv global 3.13.3 && \
		pip install --upgrade pip && \
		pip install clang-format && \
		pyenv rehash'

	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@bash -c 'export NVM_DIR="$$HOME/.nvm" && \
		[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" && \
		nvm install --lts && \
		nvm use --lts'

	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y


install-debian:
	@apt update

	@apt install -y build-essential unzip git curl cmake clang gdb golang-go \
		libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
		libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
	
	@curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
	@rm -rf /opt/nvim-linux-x86_64
	@tar -C /opt -xzf nvim-linux-x86_64.tar.gz
	@echo 'export PATH="$$PATH:$(NVIM_PATH)"' >> ~/.bashrc
	
	@rm -rf ~/.pyenv
	@curl https://pyenv.run | bash
	@echo 'export PYENV_ROOT="$$HOME/.pyenv"' >> ~/.bashrc
	@echo '[[ -d $$PYENV_ROOT/bin ]] && export PATH="$$PYENV_ROOT/bin:$$PATH"' >> ~/.bashrc
	@echo 'eval "$$(pyenv init -)"' >> ~/.bashrc
	@bash -c 'export PYENV_ROOT="$$HOME/.pyenv" && \
		export PATH="$$PYENV_ROOT/bin:$$PATH" && \
		eval "$$(pyenv init -)" && \
		pyenv install 3.13.3 && \
		pyenv global 3.13.3 && \
		pip install --upgrade pip && \
		pip install clang-format && \
		pyenv rehash'

	@curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
	@bash -c 'export NVM_DIR="$$HOME/.nvm" && \
		[ -s "$$NVM_DIR/nvm.sh" ] && \. "$$NVM_DIR/nvm.sh" && \
		nvm install --lts && \
		nvm use --lts'
	
	@bash
	@curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh -s -- -y
