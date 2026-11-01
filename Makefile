VIM ?= vim
VINT ?= .venv/bin/vint
UV ?= uv
VSPEC_DIR ?= .vim-vspec
VSPEC_VERSION ?= v1.9.2
TESTIFY_DIR ?= .vim-testify
TESTIFY_VERSION ?= v0.6.0

.PHONY: all clean install-deps lint test unit-test

all: install-deps lint test

clean:
	rm -rf $(VSPEC_DIR) $(TESTIFY_DIR)
	uv venv --clear

install-deps: $(VSPEC_DIR)/bin/prove-vspec $(TESTIFY_DIR)/plugin/testify.vim
	$(UV) sync --group dev

test: $(VSPEC_DIR)/bin/prove-vspec unit-test
	VSPEC_VIM="$(VIM)" "$(VSPEC_DIR)/bin/prove-vspec" -d "$(CURDIR)" test/

unit-test: $(TESTIFY_DIR)/plugin/testify.vim
	# TODO: Run unit tests using vim-testify

lint:
	$(VINT) autoload plugin

$(VSPEC_DIR)/bin/prove-vspec:
	git clone --depth 1 --branch "$(VSPEC_VERSION)" https://github.com/kana/vim-vspec.git "$(VSPEC_DIR)"

$(TESTIFY_DIR)/plugin/testify.vim:
	git clone --depth 1 --branch "$(TESTIFY_VERSION)" https://github.com/dhruvasagar/vim-testify.git "$(TESTIFY_DIR)"
