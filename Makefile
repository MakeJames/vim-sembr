UV ?= uv
VIM ?= vim
VINT ?= $(UV) run --group dev vint
PYTHON ?= $(UV) run --group dev python
VSPEC_DIR ?= .vim-vspec
VSPEC_VERSION ?= v1.9.2

.PHONY: all clean install-deps lint lint-test test verify-deps

all: install-deps lint test

clean:
	rm -rf $(VSPEC_DIR)
	$(UV) run --group dev pyclean --yes --debris=all .
	$(UV) venv --clear

install-deps: verify-deps $(VSPEC_DIR)/bin/prove-vspec
	$(UV) sync --group dev

test: $(VSPEC_DIR)/bin/prove-vspec lint-test
	VSPEC_VIM="$(VIM)" "$(VSPEC_DIR)/bin/prove-vspec" -d "$(CURDIR)" -- --recurse test/

lint:
	PYTHONWARNINGS="ignore:pkg_resources is deprecated as an API:UserWarning" \
		$(VINT) --style-problem autoload plugin
	$(PYTHON) tools/lint_vimscript.py autoload plugin

lint-test:
	$(UV) run --group dev pytest tools/test_lint_vimscript.py

$(VSPEC_DIR)/bin/prove-vspec:
	git clone --depth 1 --branch "$(VSPEC_VERSION)" \
		https://github.com/kana/vim-vspec.git "$(VSPEC_DIR)"

verify-deps:
	@echo "Verifying dependencies..."
	@$(VIM) --version > /dev/null 2>&1 || \
		{ echo >&2 "Error: vim is not installed. Please install vim."; exit 1; }
	@$(UV) --version > /dev/null 2>&1 || \
		{ echo >&2 "Error: uv is not installed. Please install uv."; exit 1; }
