VIM ?= vim
VINT ?= vint
PYTHON ?= python3
VSPEC_DIR ?= .vim-vspec
VSPEC_VERSION ?= v1.9.2

.PHONY: install-deps lint test

install-deps:
	$(PYTHON) -m pip install -r requirements-dev.txt

test: $(VSPEC_DIR)/bin/prove-vspec
	VSPEC_VIM="$(VIM)" "$(VSPEC_DIR)/bin/prove-vspec" -d "$(CURDIR)" test/

lint:
	$(VINT) autoload plugin

$(VSPEC_DIR)/bin/prove-vspec:
	git clone --depth 1 --branch "$(VSPEC_VERSION)" https://github.com/kana/vim-vspec.git "$(VSPEC_DIR)"
