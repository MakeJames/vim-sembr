VIM ?= vim
VINT ?= .venv/bin/vint
UV ?= uv
VSPEC_DIR ?= .vim-vspec
VSPEC_VERSION ?= v1.9.2
TESTIFY_DIR ?= .vim-testify
TESTIFY_VERSION ?= v0.6.0

.PHONY: install-deps lint test unit-test

install-deps:
	$(UV) sync --group dev

test: $(VSPEC_DIR)/bin/prove-vspec unit-test
	VSPEC_VIM="$(VIM)" "$(VSPEC_DIR)/bin/prove-vspec" -d "$(CURDIR)" test/

unit-test: $(TESTIFY_DIR)/plugin/testify.vim
	$(VIM) -Nu NONE -n -es -S scripts/run_unit_tests.vim

lint:
	$(VINT) autoload plugin

$(VSPEC_DIR)/bin/prove-vspec:
	git clone --depth 1 --branch "$(VSPEC_VERSION)" https://github.com/kana/vim-vspec.git "$(VSPEC_DIR)"

$(TESTIFY_DIR)/plugin/testify.vim:
	git clone --depth 1 --branch "$(TESTIFY_VERSION)" https://github.com/dhruvasagar/vim-testify.git "$(TESTIFY_DIR)"
