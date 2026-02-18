# ═══════════════════════════════════════════════════
#       AutoPilot-Hub - Makefile
#       Quick commands for development & operations
# ═══════════════════════════════════════════════════

.PHONY: help setup up down restart status logs clean build \
        setup-ollama health backup

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m # No Color

# Default target
help: ## Show this help message
	@echo ""
	@echo "$(GREEN)╔══════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║     AutoPilot-Hub Commands           ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""

# ── Setup ──

setup: ## Initial setup - install everything
	@echo "$(GREEN)[+] Running initial setup...$(NC)"
	@chmod +x scripts/*.sh
	@./scripts/setup.sh

install-deps: ## Install system dependencies
	@echo "$(GREEN)[+] Installing dependencies...$(NC)"
	@./scripts/install-dependencies.sh

setup-ollama: ## Pull Ollama LLM model
	@echo "$(GREEN)[+] Pulling Ollama model...$(NC)"
	@docker exec autopilot-ollama ollama pull llama3.1:8b
	@echo "$(GREEN)[✓] Model ready!$(NC)"

setup-env: ## Create .env from example
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		echo "$(GREEN)[✓] .env created. Edit it with your settings!$(NC)"; \
	else \
		echo "$(YELLOW)[!] .env already exists. Skipping.$(NC)"; \
	fi

# ── Docker Operations ──

build: ## Build all Docker images
	@echo "$(GREEN)[+] Building all images...$(NC)"
	@docker compose build

up: ## Start all services
	@echo "$(GREEN)[+] Starting AutoPilot-Hub...$(NC)"
	@docker compose up -d
	@echo "$(GREEN)[✓] All services started!$(NC)"
	@make status

up-infra: ## Start only infrastructure (DB, Redis, RabbitMQ, Ollama)
	@echo "$(GREEN)[+] Starting infrastructure...$(NC)"
	@docker compose up -d postgres redis rabbitmq ollama
	@echo "$(GREEN)[✓] Infrastructure ready!$(NC)"

up-monitoring: ## Start monitoring stack
	@echo "$(GREEN)[+] Starting monitoring...$(NC)"
	@docker compose -f docker-compose.yml \
		-f docker-compose.monitoring.yml up -d \
		prometheus grafana loki
	@echo "$(GREEN)[✓] Monitoring ready!$(NC)"

down: ## Stop all services
	@echo "$(RED)[-] Stopping AutoPilot-Hub...$(NC)"
	@docker compose down
	@echo "$(RED)[✓] All services stopped.$(NC)"

restart: ## Restart all services
	@make down
	@make up

restart-service: ## Restart a specific service (usage: make restart-service s=main-agent)
	@echo "$(YELLOW)[~] Restarting $(s)...$(NC)"
	@docker compose restart $(s)

# ── Status & Monitoring ──

status: ## Show status of all services
	@echo ""
	@echo "$(GREEN)╔══════════════════════════════════════╗$(NC)"
	@echo "$(GREEN)║     Services Status                  ║$(NC)"
	@echo "$(GREEN)╚══════════════════════════════════════╝$(NC)"
	@echo ""
	@docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

health: ## Check health of all services
	@echo "$(GREEN)[+] Checking health...$(NC)"
	@./scripts/health-check.sh

logs: ## Show logs for all services (usage: make logs or make logs s=main-agent)
	@if [ -z "$(s)" ]; then \
		docker compose logs -f --tail=100; \
	else \
		docker compose logs -f --tail=100 $(s); \
	fi

# ── Database ──

db-shell: ## Open PostgreSQL shell
	@docker exec -it autopilot-postgres \
		psql -U ${POSTGRES_USER:-autopilot} -d ${POSTGRES_DB:-autopilot_hub}

db-backup: ## Backup database
	@echo "$(GREEN)[+] Backing up database...$(NC)"
	@./scripts/backup.sh

redis-cli: ## Open Redis CLI
	@docker exec -it autopilot-redis redis-cli -a ${REDIS_PASSWORD}

# ── Development ──

shell: ## Open shell in a service (usage: make shell s=main-agent)
	@docker exec -it autopilot-$(s) /bin/bash

test: ## Run tests (usage: make test or make test s=main-agent)
	@if [ -z "$(s)" ]; then \
		echo "$(GREEN)[+] Running all tests...$(NC)"; \
		docker compose exec main-agent pytest; \
	else \
		echo "$(GREEN)[+] Running tests for $(s)...$(NC)"; \
		docker compose exec $(s) pytest; \
	fi

lint: ## Run linting
	@echo "$(GREEN)[+] Running linters...$(NC)"
	@docker compose exec main-agent flake8 .
	@docker compose exec main-agent black --check .

# ── Cleanup ──

clean: ## Remove all containers, volumes, and images
	@echo "$(RED)[!] This will remove ALL data. Are you sure? [y/N]$(NC)"
	@read -r confirm && [ "$$confirm" = "y" ] && \
		docker compose down -v --rmi all --remove-orphans || \
		echo "$(YELLOW)Cancelled.$(NC)"

clean-logs: ## Clean log files
	@find . -name "*.log" -type f -delete
	@echo "$(GREEN)[✓] Logs cleaned.$(NC)"

prune: ## Remove unused Docker resources
	@docker system prune -f
	@echo "$(GREEN)[✓] Docker pruned.$(NC)"
