# makefile to manage project
# commands:
#   - make setup-venv
#   - make examples
#   - make test-requirements
#   - make test-coverage
#   - make format
#   - make format-check
#   - make thirdpartycheck
#   - make clean

VENV_DIR := .venv
VENV_RECREATE := false
VENV_RELEASE := false

# Platform detection for virtual environment binary path
ifeq ($(OS),Windows_NT)
	VENV_BIN := $(VENV_DIR)/Scripts
	PLATFORM := windows
	PATHSEP := ;
else
	VENV_BIN := $(VENV_DIR)/bin
	PLATFORM := unix
	PATHSEP := :
endif

# Main setup-venv target - uses POSIX shell commands (works with Git Bash on Windows)
.PHONY: setup-venv
setup-venv:
	echo "Syncing project dependencies:"	
	uv sync --all-extras
	
.PHONY: test-requirements
test-requirements: setup-venv
	uv run pytest

.PHONY: test-coverage
test-coverage: setup-venv
	uv run pytest --cov --cov-report=html --cov-report=term-missing

.PHONY: format
format: setup-venv
	uv run ruff format .

.PHONY: format-check
format-check: setup-venv
	uv run ruff format --check .

.PHONY: thirdpartycheck
thirdpartycheck: setup-venv
	@echo ""
	@echo "Running third-party dependency analysis..."
	uv run python scripts/analyze_dependencies.py --format json --generate-notice --check-compatibility
	@echo "Third-party dependency check complete."

.PHONY: clean
clean:
	echo "Cleaning project..."; \
	find . -type f -name "*.pyc" -delete; \
	find . -type d -name "__pycache__" -exec rm -rf {} +; \
	find . -type d -name "log" -exec rm -rf {} +; \
	find . -type d -name ".pytest_cache" -exec rm -rf {} +; \
	find . -type d -name ".ruff_cache" -exec rm -rf {} +; \
	rm -f .coverage .coverage.*; \
	rm -rf htmlcov; \
	rm -rf logs; \
	echo "Project cleaned successfully in mode light."; \
