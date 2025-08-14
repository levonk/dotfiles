# Makefile for Dotfiles DevContainer Management
# Provides convenient commands for Docker Compose operations

# Variables for DRY principle
COMPOSE_FILE := docker-compose.yml
COMPOSE_OVERRIDE := docker-compose.override.yml
PROJECT_NAME := dotfiles
SERVICE_MAIN := dotfiles-test
SERVICE_CI := dotfiles-ci
SERVICE_BASH := dotfiles-bash-test

# Default target
.DEFAULT_GOAL := help

# Help target
.PHONY: help
help: ## Show this help message
	@echo "🔧 Dotfiles DevContainer Management"
	@echo "=================================="
	@echo ""
	@echo "Available commands:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Examples:"
	@echo "  make build     # Build the container"
	@echo "  make test      # Run automated tests"
	@echo "  make dev       # Start development environment"
	@echo "  make clean     # Clean up everything"

# Build targets
.PHONY: build
build: ## Build the dotfiles testing container
	@echo "🏗️  Building dotfiles testing container..."
	docker-compose -f $(COMPOSE_FILE) build $(SERVICE_MAIN)

.PHONY: build-all
build-all: ## Build all containers
	@echo "🏗️  Building all containers..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) build

# Development targets
.PHONY: dev
dev: ## Start interactive development environment
	@echo "🔧 Starting development environment..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) up $(SERVICE_MAIN)

.PHONY: bash-dev
bash-dev: ## Start Bash development environment
	@echo "🐚 Starting Bash development environment..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) up $(SERVICE_BASH)

.PHONY: shell
shell: ## Open shell in running container
	@echo "🐚 Opening shell in container..."
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_MAIN) zsh

# Testing targets
.PHONY: test
test: ## Run automated CI tests
	@echo "🧪 Running automated tests..."
	docker-compose -f $(COMPOSE_FILE) up --build $(SERVICE_CI)

.PHONY: test-interactive
test-interactive: ## Run tests interactively
	@echo "🧪 Running interactive tests..."
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_MAIN) tests/devcontainer-test.sh

.PHONY: test-bats
test-bats: ## Run only bats tests
	@echo "🧪 Running bats tests..."
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_MAIN) bats tests/shell-tests.bats

.PHONY: test-performance
test-performance: ## Run performance benchmarks
	@echo "⚡ Running performance tests..."
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_MAIN) tests/devcontainer-test.sh

# Utility targets
.PHONY: logs
logs: ## Show container logs
	@echo "📋 Showing container logs..."
	docker-compose -f $(COMPOSE_FILE) logs -f

.PHONY: status
status: ## Show container status
	@echo "📊 Container status:"
	docker-compose -f $(COMPOSE_FILE) ps

.PHONY: exec
exec: ## Execute command in container (usage: make exec CMD="command")
	@echo "⚡ Executing: $(CMD)"
	docker-compose -f $(COMPOSE_FILE) exec $(SERVICE_MAIN) $(CMD)

# Cleanup targets
.PHONY: stop
stop: ## Stop all containers
	@echo "🛑 Stopping containers..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) stop

.PHONY: down
down: ## Stop and remove containers
	@echo "🗑️  Stopping and removing containers..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) down

.PHONY: clean
clean: ## Clean up containers, volumes, and images
	@echo "🧹 Cleaning up..."
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) down -v --rmi local
	docker system prune -f

.PHONY: reset
reset: clean build ## Reset everything (clean + build)
	@echo "🔄 Reset completed"

# Maintenance targets
.PHONY: pull
pull: ## Pull latest base images
	@echo "⬇️  Pulling latest images..."
	docker-compose -f $(COMPOSE_FILE) pull

.PHONY: validate
validate: ## Validate Docker Compose configuration
	@echo "✅ Validating configuration..."
	docker-compose -f $(COMPOSE_FILE) config
	@echo "✅ Base configuration valid"
	docker-compose -f $(COMPOSE_FILE) -f $(COMPOSE_OVERRIDE) config > /dev/null
	@echo "✅ Override configuration valid"

# Debug targets
.PHONY: debug
debug: ## Start container with debug output
	@echo "🐛 Starting debug session..."
	docker-compose -f $(COMPOSE_FILE) run --rm -e DEBUG_MODULE_LOADING=1 -e DEBUG_SOURCING=1 $(SERVICE_MAIN) zsh

.PHONY: inspect
inspect: ## Inspect container configuration
	@echo "🔍 Container inspection:"
	docker-compose -f $(COMPOSE_FILE) config $(SERVICE_MAIN)

# CI/CD targets
.PHONY: ci-test
ci-test: ## Run CI tests (non-interactive)
	@echo "🤖 Running CI tests..."
	docker-compose -f $(COMPOSE_FILE) run --rm $(SERVICE_CI)

.PHONY: ci-validate
ci-validate: validate test ## Full CI validation (config + tests)
	@echo "✅ CI validation completed"

# Quick commands
.PHONY: up
up: build dev ## Build and start development environment

.PHONY: restart
restart: down up ## Restart the development environment
