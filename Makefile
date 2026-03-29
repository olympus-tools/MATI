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
	@if [ -d "$(VENV_DIR)" ]; then \
		echo "Virtual environment '$(VENV_DIR)' already exists. For recreation add 'VENV_RECREATE=true' to cli."; \
		if [ "$(VENV_RECREATE)" = "true" ] || [ "$(VENV_RECREATE)" = "TRUE" ]; then \
			echo "Removing existing virtual environment '$(VENV_DIR)'..."; \
			rm -rf "$(VENV_DIR)"; \
		else \
			exit 0; \
		fi; \
	fi; \
	echo "Creating virtual environment '$(VENV_DIR)'..."; \
	python -m venv "$(VENV_DIR)" || { echo "Error: Failed to create virtual environment."; exit 1; }; \
	echo "Installing project dependencies in virtual environment '$(VENV_DIR)'..."; \
	\
	# Check if .git exists to decide on versioning strategy for editable install \
	if [ ! -d ".git" ]; then \
		echo "NOTE: .git directory not found. Setting pretend version for installation."; \
		SETUPTOOLS_SCM_PRETEND_VERSION_FOR_MATI=0.0.1 "$(VENV_BIN)/pip" install -e ".[dev,test]" || { echo "Error: Failed to install dependencies (no Git)."; exit 1; }; \
	else \
		echo "NOTE: .git directory found. Using setuptools_scm for versioning."; \
		"$(VENV_BIN)/pip" install -e ".[dev,test]" || { echo "Error: Failed to install dependencies (with Git)."; exit 1; }; \
	fi

.PHONY: test-requirements
test-requirements: setup-venv
	@"$(VENV_BIN)/pytest"

.PHONY: test-coverage
test-coverage: setup-venv
	@"$(VENV_BIN)/pytest" --cov --cov-report=html --cov-report=term-missing

.PHONY: format
format: setup-venv
	@"$(VENV_BIN)/ruff" format .

.PHONY: format-check
format-check: setup-venv
	@"$(VENV_BIN)/ruff" format --check .

.PHONY: thirdpartycheck
thirdpartycheck: setup-venv
	@echo ""
	@echo "Running third-party dependency analysis..."
	@"$(VENV_BIN)/python" scripts/analyze_dependencies.py --format json --generate-notice --check-compatibility
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
